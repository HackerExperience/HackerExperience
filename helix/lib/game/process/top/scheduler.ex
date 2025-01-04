defmodule Game.Process.TOP.Scheduler do
  require Logger
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.Process.Resources
  alias Game.{Process}

  def is_completed?(%Process{resources: resources} = process) do
    true = not is_nil(resources.allocated)
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    # total_processed >= objective
    total_processed = calculate_total_processed(process, now)
    Resources.completed?(total_processed, resources.objective)
  end

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

  def forecast([]), do: :empty

  def forecast(processes) do
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

  def drop_processes(processes) do
    Enum.reduce(processes, [], fn process, acc ->
      {:ok, event} = Svc.Process.delete(process, :killed)
      [event | acc]
    end)
  end

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

  # @docp Estimates time to complete the process
  defp calculate_completion_ts(processed, allocated, objective, now) do
    # processed + (allocation * t) = objective
    # (allocation * t) = objective - processed
    # t = (objective - processed) / allocation
    work_left =
      objective
      |> Resources.sub(processed)
      |> Resources.div(allocated)

    {_, seconds_left} = Resources.max_value(work_left)

    seconds_left
    |> Decimal.to_float()
    |> Kernel.*(1_000)
    |> trunc()
    |> Kernel.+(now)
  end
end
