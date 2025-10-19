defmodule Game.Scanner.Worker.TaskCompletion do
  use GenServer

  require Logger

  alias Renatils.DateTime, as: DateTimeUtils
  alias Core.Event
  alias Game.Services, as: Svc

  alias Game.Events.Scanner.TaskCompleted, as: ScannerTaskCompletedEvent

  @event_client Application.compile_env(:helix, :event, Core.Event)
  @scanneable_client Application.compile_env(:helix, :scanneable, Game.Scanner.Scanneable)

  # Look for completed tasks every 5s
  @refresh_interval 5_000

  # Batch write all changes 100ms after the last task finished processing
  @batch_writer_interval 100

  # Public API

  def start_link([universe, shard_id]) do
    name =
      __MODULE__
      |> Module.concat(universe)
      |> Module.concat("#{shard_id}")

    GenServer.start_link(__MODULE__, [universe, shard_id], name: name)
  end

  def trigger_refresh(pid) do
    GenServer.call(pid, :trigger_refresh)
  end

  # GenServer

  def init([universe, shard_id]) do
    refresh_timer = reenqueue_worker()

    state = %{
      universe: universe,
      shard_id: shard_id,
      batch_id: 1,
      processing_tasks: [],
      completed_tasks: [],
      refresh_timer: refresh_timer,
      batch_writer_timer: nil
    }

    # TODO: State handling via specific module
    Process.put(:helix_universe, universe)
    Process.put(:helix_universe_shard_id, shard_id)

    {:ok, state}
  end

  def handle_call(:trigger_refresh, _, state) do
    refresh(state)
    {:reply, :ok, state}
  end

  def handle_info(:refresh, state) do
    new_refresh_timer = reenqueue_worker()

    # Make sure to never call refresh/1 if there still are processing_tasks (meaning the batch writer hasn't executed yet)

    processing_tasks = refresh(state)

    new_state =
      state
      |> Map.put(:refresh_timer, new_refresh_timer)
      |> Map.put(:processing_tasks, processing_tasks)

    {:noreply, new_state}
  end

  def handle_info(:batch_writer, state) do
    Core.with_context(:scanner, :write, fn ->
      state.completed_tasks
      |> Enum.each(fn
        {task, _ref, _pid, {:ok, next_target_id, duration}} ->
          Svc.Scanner.retarget_task(task, next_target_id, duration)

        {task, _ref, _pid, {:ok, :empty}} ->
          # TODO: Here's where backoff kicks in. Implement and test
          Svc.Scanner.retarget_task(task, nil, 60)
      end)
    end)

    new_state =
      state
      |> Map.put(:batch_id, state.batch_id + 1)
      |> Map.put(:processing_tasks, [])
      |> Map.put(:completed_tasks, [])
      |> Map.put(:batch_writer_timer, nil)

    {:noreply, new_state}
  end

  # The `Event.emit_async` call we make here returns the event result as an info message. We don't
  # care about this one.
  def handle_info({ref, {:event_result, _}}, state) when is_reference(ref),
    do: {:noreply, state}

  def handle_info({ref, result}, state) when is_reference(ref) do
    {task, _, pid} = Enum.find(state.processing_tasks, fn {_, task_ref, _} -> task_ref == ref end)

    new_completed_tasks = [{task, ref, pid, result} | state.completed_tasks]

    batch_writer_timer =
      if length(new_completed_tasks) == length(state.processing_tasks) do
        enqueue_batch_writer()
      end

    new_state =
      state
      |> Map.put(:completed_tasks, new_completed_tasks)
      |> Map.put(:batch_writer_timer, batch_writer_timer)

    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, _, _, :normal}, state) do
    # The spawned tasks finished executing successfully
    {:noreply, state}
  end

  # TODO: Test this scenario
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    # There was an exception in one of the spawned tasks. Log and move on
    Logger.error("#{inspect(ref)} crashed: #{inspect(reason)}\n\n#{inspect(state)}")
    {:noreply, state}
  end

  # Private

  defp refresh(_state) do
    Core.with_context(:scanner, :read, fn ->
      now = DateTimeUtils.ts_now()

      completed_tasks = Svc.Scanner.list_tasks(by_completed: [now])

      # For each completed task that has an actual target, emit an ScannerTaskCompletedEvent. This
      # will ensure the scanned object is made visible to the player.
      # TODO: Use stream here
      completed_tasks
      |> Stream.reject(&is_nil(&1.target_id))
      |> Stream.map(fn task ->
        ev_relay = Event.Relay.new(task)

        task
        |> ScannerTaskCompletedEvent.new()
        |> Event.Relay.put(ev_relay)
      end)
      |> Enum.to_list()
      |> @event_client.emit_async()

      helix_universe = Process.get(:helix_universe)
      helix_universe_shard_id = Process.get(:helix_universe_shard_id)

      # For each completed task, find out what it's next target should be.
      completed_tasks
      |> Enum.map(fn task ->
        %{pid: task_pid, ref: task_ref} =
          Task.Supervisor.async_nolink(
            {:via, PartitionSupervisor, {Helix.TaskSupervisor, self()}},
            fn ->
              # TODO: State handling via specific module
              Process.put(:helix_universe, helix_universe)
              Process.put(:helix_universe_shard_id, helix_universe_shard_id)

              @scanneable_client.retarget(task)
            end
          )

        {task, task_ref, task_pid}
      end)
    end)
  end

  defp reenqueue_worker do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp enqueue_batch_writer do
    Process.send_after(self(), :batch_writer, @batch_writer_interval)
  end
end
