defmodule Game.Process.TOP.Scheduler do
  use Docp
  require Logger
  alias Core.Event
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.Process.Resources
  alias Game.{Process, Server}

  @doc """
  Checks whether the Process is completed (i.e. its `objective` was reached in full, for every
  resource).
  """
  @spec is_completed?(Process.t()) ::
          true
          | {false, {Resources.name(), Resources.value()}}
  def is_completed?(%Process{resources: resources} = process) do
    true = not is_nil(resources.allocated)
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    # total_processed >= objective
    total_processed = calculate_total_processed(process, now)
    Resources.completed?(total_processed, resources.objective)
  end

  @doc """
  "Simulates" a process, by taking into consideration everything that was processed since the last
  checkpoint (if any) until `now`. This will then be persisted into the `processed` entry.

  This is particularly useful when allocation for a particular process changes. We need to perform a
  "checkpoint" and make sure we know how many resources were processed up to this point. With the
  new allocations, resources will be processed at a different rate than before, but we won't lose
  track of how much progress has been made so far. We'll also (re-)calculate the estimated
  completion date.

  Because of this, we only update the `processed` information if the allocation has changed. If the
  allocation is the same as before, then nothing needs to change, since the previously computed
  completion date won't change, and neither will the `processed` resources once the process finally
  completes.
  """
  @spec simulate(Process.t(), current_timestamp :: integer) ::
          Process.t()
          | no_return
  def simulate(%Process{next_allocation: nil}, _),
    do: raise("Can't simulate a process that has not gone through TOP.Allocator")

  def simulate(%Process{next_allocation: v, resources: %{allocated: v}} = process, _) do
    Logger.debug("Process #{process.id.id} retained the same allocations")
    %{process | next_allocation: :unchanged}
  end

  def simulate(%Process{next_allocation: next_alloc} = process, now) do
    if is_nil(process.resources.allocated) do
      Logger.debug("Process #{process.id.id} had its allocation defined")
    else
      Logger.debug("Process #{process.id.id} had its allocation changed")
    end

    new_status = if process.status == :awaiting_allocation, do: :running, else: process.status

    # Resources the process has processed up to this point
    new_processed = calculate_total_processed(process, now)

    # Estimated timestamp in which process will reach resource goal, at `next_alloc` rate
    completion_ts =
      if process.status != :paused do
        calculate_completion_ts(new_processed, next_alloc, process.resources.objective, now)
      else
        # Paused processes will never complete
        nil
      end

    new_resources =
      process.resources
      |> Map.put(:allocated, next_alloc)
      |> Map.put(:processed, new_processed)

    process
    |> Map.put(:status, new_status)
    |> Map.put(:resources, new_resources)
    |> Map.put(:last_checkpoint_ts, now)
    |> Map.put(:estimated_completion_ts, completion_ts)
    |> Map.put(:next_allocation, :updated)
  end

  @doc """
  Persists to the database the changes made in a process, *if* any changes were made.

  We know whether changes were made based on the value of `:next_allocation`. If it is `:updated`,
  then this process allocation changed (during the Allocator phase) and the simulation (done in the
  `simulate/2` function above) merged the changes into the process schema. Now we just need to grab
  those changes and write to disk.
  """
  @spec update_modified_processes(Server.id(), [Process.t()]) ::
          {:ok, updated_processes :: integer}
          | {:error, term}
  def update_modified_processes(server_id, processes) do
    processes_to_update = Enum.filter(processes, &(&1.next_allocation == :updated))

    Core.begin_context(:server, server_id, :write)

    Enum.reduce_while(processes_to_update, {:ok, 0}, fn process, {:ok, total} ->
      changes =
        %{
          status: process.status,
          resources: process.resources,
          last_checkpoint_ts: process.last_checkpoint_ts,
          estimated_completion_ts: process.estimated_completion_ts
        }

      process
      |> Process.update(changes)
      |> DB.update()
      |> case do
        {:ok, _} ->
          {:cont, {:ok, total + 1}}

        {:error, reason} ->
          Logger.error("Unable to update process: #{inspect(reason)}")
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, total} ->
        DB.commit()
        Logger.debug("Updated #{total} process(es)")
        {:ok, total}

      {:error, reason} ->
        # TODO: Test this scenario
        DB.rollback()
        {:error, reason}
    end
  end

  @doc """
  Iterates over the processes and finds the one that will complete next. Returns `:empty` if no
  processes will ever complete (say, because the TOP is empty or every remaining process is paused).
  """
  @spec forecast([Process.t()]) ::
          {:next, Process.t()}
          | :empty
  def forecast([_ | _] = processes) do
    Enum.reduce(processes, {nil, :infinity}, fn process, {_, cur_next_completion_ts} = acc ->
      # Sanity check: every non-paused process *must* have an estimated completion TS
      if process.status != :paused,
        do: true = not is_nil(process.estimated_completion_ts)

      cond do
        process.status == :paused ->
          acc

        process.estimated_completion_ts <= cur_next_completion_ts ->
          {process, process.estimated_completion_ts}

        true ->
          acc
      end
    end)
    |> case do
      {%Process{} = next_process, _next_ts} ->
        {:next, next_process}

      {nil, :infinity} ->
        :empty
    end
  end

  def forecast([]), do: :empty

  @doc """
  Returns the newest process (i.e. most recently created) that allocates any amount of the given
  resource. This is particularly useful for recursively killing processes in the event of resource
  overflow.
  """
  @spec find_newest_using_resource([Process.t()], Resources.name()) ::
          Process.t()
          | nil
  def find_newest_using_resource(processes, resource_name) when is_list(processes) do
    # Sort processes by creation date. IDs are sequential so we can use that instead of dates
    processes
    |> Enum.sort_by(& &1.id.id, :desc)
    |> Enum.find(fn %{resources: %{allocated: %Resources{} = allocated}} ->
      case get_in(allocated, [Access.key!(resource_name)]) do
        %Decimal{} ->
          true

        nil ->
          false
      end
    end)
  end

  @doc """
  Drops (kills, deletes) the given processes. This may happen in the scenario of resource overflow.
  """
  @spec drop_processes([Process.t()]) ::
          [Event.t()]
  def drop_processes(processes) do
    Enum.reduce(processes, [], fn process, acc ->
      {:ok, event} = Svc.Process.delete(process, :killed)
      [event | acc]
    end)
  end

  @docp """
  Calculates total processed resources. This can be achieved by simply multiplicating the current
  allocation by the time that has passed since the last checkpoint (or creation date, if there is
  no previous checkpoint).
  """
  defp calculate_total_processed(%{resources: resources} = process, now) do
    last_checkpoint = Process.get_last_checkpoint_ts(process)

    # Time elapsed from the last_checkpoint until now
    diff_s =
      max(now - last_checkpoint, 0)
      |> Kernel./(1_000)
      |> to_string()
      |> Decimal.new()

    # total_processed = processed + (allocated * last_checkpoint_diff)
    (resources.allocated || Resources.initial())
    |> Resources.map(&Decimal.mult(&1, diff_s))
    |> Resources.sum(resources.processed || Resources.initial())
  end

  @docp """
  Estimates the time it will take to complete the process.

  processed + (allocated * t) = objective
  (allocated * t) = objective - processed
  t = (objective - processed) / allocated
  """
  defp calculate_completion_ts(processed, allocated, objective, now) do
    work_left =
      objective
      |> Resources.sub(processed)
      |> Resources.div(allocated)

    {_, seconds_left} = Resources.max_value(work_left)

    # Convert from second to millisecond and add to the current time to return the estimated
    # completion timestamp (with millisecond precision)
    seconds_left
    |> Decimal.to_float()
    |> Kernel.*(1_000)
    |> trunc()
    |> Kernel.+(now)
  end
end
