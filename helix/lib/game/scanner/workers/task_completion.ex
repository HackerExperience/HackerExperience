defmodule Game.Scanner.Worker.TaskCompletion do
  use GenServer

  require Logger
  require Hotel.Tracer

  alias Hotel.Tracer
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

  # GenServer

  def init([universe, shard_id]) do
    Logger.metadata(worker_type: :task_completion, universe: universe, shard_id: shard_id)

    refresh_timer = reenqueue_worker()

    state = %{
      universe: universe,
      shard_id: shard_id,
      batch_id: 1,
      processing_tasks: [],
      completed_tasks: [],
      refresh_timer: refresh_timer,
      batch_writer_timer: nil,
      refresh_tracer_ctx: nil
    }

    # TODO: State handling via specific module
    Process.put(:helix_universe, universe)
    Process.put(:helix_universe_shard_id, shard_id)

    {:ok, state}
  end

  def handle_info(:refresh, %{processing_tasks: []} = state) do
    new_refresh_timer = reenqueue_worker()

    Tracer.start_span("TaskCompletion.refresh")
    tracer_ctx = Tracer.current_ctx()

    processing_tasks = refresh(state)

    # If there are no tasks to process, we should end the trace right now
    tracer_ctx =
      if Enum.empty?(processing_tasks) do
        Tracer.end_span()
        nil
      else
        tracer_ctx
      end

    new_state =
      state
      |> Map.put(:refresh_timer, new_refresh_timer)
      |> Map.put(:processing_tasks, processing_tasks)
      |> Map.put(:refresh_tracer_ctx, tracer_ctx)

    {:noreply, new_state}
  end

  def handle_info(:refresh, state) do
    processing_tasks_count = Enum.count(state.processing_tasks)
    Logger.warning("There are #{processing_tasks_count} running tasks; ignoring refresh")
    {:noreply, state}
  end

  def handle_info(:batch_writer, state) do
    Hotel.Tracer.with_span("TaskCompletion.batch_writer", fn ->
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

    finished_all_tasks? = length(new_completed_tasks) == length(state.processing_tasks)

    # We only enqueue the :batch_writer message once all tasks finished processing
    batch_writer_timer = if finished_all_tasks?, do: enqueue_batch_writer()

    # Once all tasks have been processed, end the root span. Don't modify the context if the refresh
    # operation is still undergoing.
    refresh_tracer_ctx =
      if finished_all_tasks? do
        Tracer.set_ctx(state.refresh_tracer_ctx)
        Tracer.end_span()
        nil
      else
        state.refresh_tracer_ctx
      end

    new_state =
      state
      |> Map.put(:completed_tasks, new_completed_tasks)
      |> Map.put(:refresh_tracer_ctx, refresh_tracer_ctx)
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

      tracer_ctx = Hotel.Tracer.current_ctx()

      # For each completed task, find out what its next target should be.
      completed_tasks
      |> Enum.map(fn task ->
        # TODO: Set max concurrency here
        %{pid: task_pid, ref: task_ref} =
          Task.Supervisor.async_nolink(
            {:via, PartitionSupervisor, {Helix.TaskSupervisor, self()}},
            fn ->
              Hotel.Tracer.set_ctx(tracer_ctx)

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
