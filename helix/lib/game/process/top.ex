defmodule Game.Process.TOP do
  @moduledoc """
  The Table Of Processes (TOP) is responsible for recalculating the processes completion date, as
  well as handling process signaling.

  It is a per-Server GenServer. Each (game) Server with active processes have their own (and only)
  instance of the TOP.
  """

  use GenServer

  require Logger

  alias Feeb.DB
  alias Core.Event
  alias Game.Services, as: Svc
  alias Game.Process.{Executable, Signalable}
  alias Game.{ProcessRegistry, Server}
  alias __MODULE__

  alias Game.Events.Process.Completed, as: ProcessCompletedEvent
  alias Game.Events.TOP.Recalcado, as: TOPRecalcadoEvent

  # Public

  @doc """
  On application boot, instantiate the TOP for each in-game server with active processes.
  """
  def on_boot({universe, shard_id}) do
    Process.put(:helix_universe, universe)
    Process.put(:helix_universe_shard_id, shard_id)

    :universe
    |> Core.with_context(:read, fn ->
      DB.all({:processes_registry, :servers_with_processes}, [], format: :type)
    end)
    |> Enum.each(fn %{server_id: server_id} ->
      {:ok, _} = TOP.Registry.fetch_or_create({server_id, universe, shard_id})
    end)

    :ok
  end

  # GenServer callbacks

  def start_link({%Server.ID{id: raw_id} = server_id, helix_universe, helix_universe_shard_id}) do
    # TODO: Find a way to move to a single module "dirty" state like this (see also Dispatcher)
    # helix_universe = Process.get(:helix_universe)
    # helix_universe_shard_id = Process.get(:helix_universe_shard_id) || raise "Missing helix data"

    GenServer.start_link(
      __MODULE__,
      {helix_universe, helix_universe_shard_id, server_id},
      name: with_registry({raw_id, helix_universe, helix_universe_shard_id})
    )
  end

  def execute(process_mod, server_id, params, meta) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:execute, process_mod, params, meta})
  end

  # GenServer API

  def init({universe, universe_shard_id, server_id}) do
    # PS: shard_id may not be necessary here, but overall I think it's better to relay the full ctx
    Process.put(:helix_universe, universe)
    Process.put(:helix_universe_shard_id, universe_shard_id)

    relay = Event.Relay.new(:top, %{server_id: server_id})
    Process.put(:helix_event_relay, relay)

    data = %{
      server_id: server_id,
      entity_id: nil,
      server_resources: nil,
      next: nil
    }

    {:ok, data, {:continue, :bootstrap}}
  end

  def handle_continue(:bootstrap, state) do
    # Here we fetch every process in said server
    {processes, meta} =
      Core.with_context(:server, state.server_id, :read, fn ->
        {DB.all(Game.Process), Svc.Server.get_meta(state.server_id)}
      end)

    schedule =
      state
      |> Map.put(:server_resources, meta.resources)
      |> Map.put(:entity_id, meta.entity_id)
      |> run_schedule(processes, :boot)

    {:noreply, schedule.state}
  end

  def handle_call({:execute, process_mod, params, meta}, _from, state) do
    with {:ok, new_process, creation_events} =
           Executable.execute(process_mod, state.server_id, state.entity_id, params, meta),
         %{dropped: [], state: new_state} <-
           run_schedule(state, state.server_id, :insert, creation_events) do
      new_process =
        Core.with_context(:server, state.server_id, :read, fn ->
          # TODO: Process Service should be responsible for handling context
          Svc.Process.fetch!(by_id: new_process.id)
        end)

      {:reply, {:ok, new_process}, new_state}
    else
      %{dropped: [_ | _], state: new_state} ->
        {:reply, {:error, :overflow}, new_state}

      {:error, _reason} ->
        raise "TODO!"
    end
  end

  def handle_info(:next_process_completed, %{next: {process, _, _}} = state) do
    process =
      Core.with_context(:server, state.server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process.id)
      end)

    with true <- TOP.Scheduler.is_completed?(process) do
      process_completed_event = ProcessCompletedEvent.new(process)

      case Signalable.sigterm(process) do
        :delete ->
          # signaled_event = ProcessSignaledEvent.new(process, :sigterm, :delete)
          remaining_processes = delete_completed_process(state.server_id, process)

          schedule =
            run_schedule(state, remaining_processes, :completion, [process_completed_event])

          {:noreply, schedule.state}

        {:retarget, _new_objective, _registry_changes} ->
          raise "TODO"
      end
    else
      {false, {resource, objective_left}} ->
        # Process hasn't really completed; warn and re-run the scheduler
        i = "there are #{inspect(objective_left)} units of #{resource} left to be processed"
        Logger.warning("Attempted to complete process #{process.id.id} but it isn't finished: #{i}")
        {:stop, :wrong_schedule, state}
    end
  end

  # Reference from `Event.emit_async/1`; it's safe to ignore it
  def handle_info({_ref, {:event_result, _}}, state),
    do: {:noreply, state}

  # DOWN message from `Event.emit_async/1`; it's safe to ignore it
  def handle_info({:DOWN, _, _, _, :normal}, state),
    do: {:noreply, state}

  def handle_info({:DOWN, _, _, _, _} = msg, state) do
    Logger.warning("TOP #{inspect(self())} received abnormal DOWN message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp delete_completed_process(server_id, process) do
    # The process has reached its target. We can delete it from the database and send SIGTERM
    remaining_processes =
      Core.with_context(:server, server_id, :write, fn ->
        # TODO: Move to Svc layer
        DB.delete(process)

        # TODO: Move to Svc layer
        DB.all(Game.Process)
      end)

    Core.with_context(:universe, :write, fn ->
      # This is, of course, TODO. FeebDB needs to support delete based on query
      # (akin to Repo.delete_all)
      process_registry =
        DB.all(ProcessRegistry)
        |> Enum.find(&(&1.server_id == server_id && &1.process_id == process.id))

      # TODO: Move to Svc layer
      DB.delete({:processes_registry, :delete}, process_registry, [server_id, process.id])
    end)

    remaining_processes
  end

  defp run_schedule(state, processes_or_server_id, reason, events \\ [])

  defp run_schedule(state, %Server.ID{} = server_id, reason, events) do
    processes =
      Core.with_context(:server, server_id, :read, fn ->
        DB.all(Game.Process)
      end)

    run_schedule(state, processes, reason, events)
  end

  defp run_schedule(state, processes, reason, events) when is_list(processes) do
    {duration, result} = :timer.tc(fn -> do_run_schedule(state, processes, reason) end)

    duration = get_duration(duration)

    case result.state.next do
      {_, time_left, _} ->
        Logger.debug("Scheduled processes in #{duration}; will wake up in #{time_left}ms")

      nil ->
        Logger.debug("Scheduled processes in #{duration}; TOP is empty -- won't wake up")
    end

    Event.emit_async(result.events ++ events)
    %{state: result.state, dropped: result.dropped}
  end

  defp do_run_schedule(
         %{server_id: server_id, server_resources: resources} = state,
         processes,
         reason
       ) do
    with {:ok, allocated_processes} <- TOP.Allocator.allocate(server_id, resources, processes),
         now = DateTime.utc_now() |> DateTime.to_unix(:millisecond),
         processes = Enum.map(allocated_processes, &TOP.Scheduler.simulate(&1, now)),
         {:ok, modified_procs} <- TOP.Scheduler.update_modified_processes(server_id, processes) do
      top_recalcado_event =
        if reason != :boot or modified_procs == 0 do
          TOPRecalcadoEvent.new(server_id, processes)
        else
          # We don't need to emit the TOPRecalcadoEvent if this TOP just booted and nothing changed
          nil
        end

      case TOP.Scheduler.forecast(processes) do
        {:next, next_process} ->
          now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
          time_left = max(next_process.estimated_completion_ts - now + 10, 0)
          timer_ref = Process.send_after(self(), :next_process_completed, time_left)

          %{
            state: %{state | next: {next_process, time_left, timer_ref}},
            dropped: [],
            events: [top_recalcado_event]
          }

        :empty ->
          # TODO: Hibernate? Kill TOP? if empty
          %{
            state: %{state | next: nil},
            dropped: [],
            events: [top_recalcado_event]
          }
      end
    else
      {:error, {:overflow, _overflowed_resources}} ->
        # Returns: {:ok, <next>, <new_state>, <dropped>, top_recalcado_event}
        # handle_allocation_overflow(state, processes, overflowed_resources)
        raise "TODO"
    end
  end

  defp with_registry(key) do
    {:via, Registry, {TOP.Registry.name(), key}}
  end

  defp get_duration(d) when d < 1000, do: "#{d}μs"
  defp get_duration(d) when d < 10_000, do: "#{Float.round(d / 1000, 2)}ms"
  defp get_duration(d) when d < 100_000, do: "#{Float.round(d / 1000, 1)}ms"
  defp get_duration(d), do: "#{trunc(d / 1000)}ms"
end
