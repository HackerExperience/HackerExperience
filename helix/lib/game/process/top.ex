defmodule Game.Process.TOP do
  @moduledoc """
  The Table Of Processes (TOP) is responsible for recalculating the processes completion date, as
  well as handling process signaling.

  It is a per-Server GenServer. Each (game) Server with active processes have their own (and only)
  instance of the TOP.
  """

  use GenServer
  use Docp

  require Logger

  alias Feeb.DB
  alias Core.Event
  alias Game.Services, as: Svc
  alias Game.Process.{Executable, Resources, Signalable}
  alias Game.{Entity, Process, Server}
  alias __MODULE__

  alias Game.Events.TOP.Recalcado, as: TOPRecalcadoEvent

  @typedocp "Post-initialization GenServer state"
  @typep state ::
           %{
             server_id: Server.id(),
             entity_id: Entity.id(),
             server_resources: Resources.t(),
             next: {Process.t(), time_left_ms :: integer, reference} | nil
           }

  @typedocp "GenServer state before the bootstrap phase"
  @typep initial_state ::
           %{
             server_id: Server.id(),
             entity_id: nil,
             server_resources: nil,
             next: nil
           }

  @typedocp """
  Reasons that led the Scheduler to be triggered.

  - boot: when the TOP first starts up.
  - insert: when a new process is added to the TOP.
  - completion: when a process reaches its objective.
  - resources_changed: when the total available server resources changed.
  - resume: when a process is resumed.
  - pause: when a process is paused.
  - renice: when a process has its priority changed.
  """
  @typep scheduler_run_reason ::
           :boot
           | :insert
           | :completion
           | :resources_changed
           | {:resume, Process.id()}
           | {:pause, Process.id()}
           | {:renice, Process.id()}
           | {:killed, Process.id()}

  # Public

  @doc """
  On application boot, instantiate the TOP for each in-game server with active processes.
  """
  def on_boot({universe, shard_id}) do
    Elixir.Process.put(:helix_universe, universe)
    Elixir.Process.put(:helix_universe_shard_id, shard_id)

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

  @spec execute(module, Server.id(), Entity.id(), map, map) ::
          {:ok, Process.t()}
          | {:error, :overflow | :internal}
  def execute(process_mod, server_id, entity_id, params, meta) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:execute, process_mod, entity_id, params, meta})
  end

  @spec pause(Process.t()) ::
          {:ok, Process.t()}
          | {:error, :rejected | term}
  def pause(%Process{server_id: server_id} = process) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:pause, process})
  end

  @spec resume(Process.t()) ::
          {:ok, Process.t()}
          | {:error, :rejected | :overflow | term}
  def resume(%Process{server_id: server_id} = process) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:resume, process})
  end

  @spec renice(Process.t(), Process.priority()) ::
          {:ok, Process.t()}
          | {:error, term}
  def renice(%Process{server_id: server_id} = process, priority) when is_integer(priority) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:renice, process, priority})
  end

  @doc """
  Delivers the given Signal to the given Process, performing whatever action was returned by the
  process' Signalable.
  """
  @spec signal(Process.t(), Signalable.signal(), term) ::
          {:ok, Signalable.action()}
  def signal(%Process{server_id: server_id} = process, signal, xargs \\ []) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:signal, process, signal, xargs})
  end

  @spec on_server_resources_changed(Server.id()) ::
          :ok
  def on_server_resources_changed(server_id) do
    server_id
    |> TOP.Registry.fetch!()
    |> GenServer.call({:on_server_resources_changed})
  end

  # GenServer API

  def init({universe, universe_shard_id, server_id}) do
    # PS: shard_id may not be necessary here, but overall I think it's better to relay the full ctx
    Elixir.Process.put(:helix_universe, universe)
    Elixir.Process.put(:helix_universe_shard_id, universe_shard_id)

    relay = Event.Relay.new(:top, %{server_id: server_id})
    Elixir.Process.put(:helix_event_relay, relay)

    data = %{
      server_id: server_id,
      entity_id: nil,
      server_resources: nil,
      next: nil
    }

    {:ok, data, {:continue, :bootstrap}}
  end

  def handle_continue(:bootstrap, state) do
    {state, processes} = fetch_initial_data(state)
    schedule = run_schedule(state, processes, :boot)
    {:noreply, schedule.state}
  end

  @spec fetch_initial_data(initial_state) ::
          {state, [Process.t()]}
  defp fetch_initial_data(state) do
    {processes, meta} =
      Core.with_context(:server, state.server_id, :read, fn ->
        {DB.all(Process), Svc.Server.get_meta(state.server_id)}
      end)

    state =
      state
      |> Map.put(:server_resources, meta.resources)
      |> Map.put(:entity_id, meta.entity_id)

    {state, processes}
  end

  def handle_call({:execute, process_mod, entity_id, params, meta}, _from, state) do
    with {:ok, new_process, creation_events} <-
           Executable.execute(process_mod, state.server_id, entity_id, params, meta),
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

      {:error, reason} ->
        Logger.error("Failed to execute process: #{inspect(reason)}")
        {:reply, {:error, :internal}, state}
    end
  end

  def handle_call({:pause, process}, _from, state) do
    with {:signal_action, :pause} <- {:signal_action, Signalable.sigstop(process)},
         {:ok, _, [process_paused_event]} <- Svc.Process.pause(process) do
      result = run_schedule(state, state.server_id, {:pause, process.id}, [process_paused_event])

      # Fetch from disk the process we just paused because its allocation has changed
      paused_process =
        Core.with_context(:server, state.server_id, :read, fn ->
          Svc.Process.fetch!(by_id: process.id)
        end)

      {:reply, {:ok, paused_process}, result.state}
    else
      {:signal_action, :noop} ->
        {:reply, {:error, :rejected}, state}

      {:error, reason} ->
        Logger.error("Unable to pause process: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:resume, process}, _from, state) do
    with {:signal_action, :resume} <- {:signal_action, Signalable.sigcont(process)},
         {:ok, _, [process_resumed_event]} <- Svc.Process.resume(process),
         %{dropped: [], paused: [], state: new_state} <-
           run_schedule(state, state.server_id, {:resume, process.id}, [process_resumed_event]) do
      resumed_process =
        Core.with_context(:server, state.server_id, :read, fn ->
          Svc.Process.fetch!(by_id: process.id)
        end)

      {:reply, {:ok, resumed_process}, new_state}
    else
      {:signal_action, :noop} ->
        {:reply, {:error, :rejected}, state}

      # We were unable to resume this process because there are insufficient resources in the server
      %{paused: [_ | _], state: new_state} ->
        {:reply, {:error, :overflow}, new_state}

      {:error, reason} ->
        Logger.error("Unable to resume process: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:renice, process, priority}, _from, state) do
    # Re-fetch the process inside the TOP to avoid race conditions
    process = refetch_process!(process)

    with {:signal_action, :renice} <- {:signal_action, Signalable.sig_renice(process)},
         {:ok, process, [process_reniced_event]} <- Svc.Process.renice(process, priority) do
      result = run_schedule(state, state.server_id, {:renice, process.id}, [process_reniced_event])
      {:reply, {:ok, refetch_process!(process)}, result.state}
    else
      {:error, reason} ->
        Logger.error("Unable to renice process: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:signal, process, signal, xargs}, _from, state) do
    action = apply(Signalable, signal, [process, xargs])

    {should_reschedule?, reschedule_reason, signal_events} =
      case action do
        :delete ->
          {:ok, process_killed_event} = Svc.Process.delete(process, :killed)
          {true, {:killed, process.id}, [process_killed_event]}

        :noop ->
          {false, nil, []}
      end

    if should_reschedule? do
      result = run_schedule(state, state.server_id, reschedule_reason, signal_events)
      {:reply, {:ok, action}, result.state}
    else
      {:reply, {:ok, action}, state}
    end
  end

  def handle_call({:on_server_resources_changed}, _from, state) do
    {state, processes} = fetch_initial_data(state)
    schedule = run_schedule(state, processes, :resources_changed)
    {:reply, :ok, schedule.state}
  end

  def handle_info(:next_process_completed, %{next: {process, _, _}} = state) do
    process = refetch_process!(process)

    case {TOP.Scheduler.is_completed?(process), Signalable.sigterm(process)} do
      # Process completed and we are supposed to delete it
      {true, :delete} ->
        {:ok, process_completed_event} = Svc.Process.delete(process, :completed)

        remaining_processes =
          Core.with_context(:server, state.server_id, :read, fn ->
            # TODO: Move to Svc layer
            DB.all(Process)
          end)

        schedule =
          run_schedule(state, remaining_processes, :completion, [process_completed_event])

        {:noreply, schedule.state}

      # Process completed and we have to retarget it
      {true, {:retarget, _new_objective, _registry_changes}} ->
        raise "TODO"

      # Process hasn't really completed; warn and re-run the scheduler
      {{false, {resource, objective_left}}, _} ->
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

  defp run_schedule(state, processes_or_server_id, reason, events \\ [])

  defp run_schedule(state, %Server.ID{} = server_id, reason, events) do
    processes =
      Core.with_context(:server, server_id, :read, fn ->
        DB.all(Process)
      end)

    run_schedule(state, processes, reason, events)
  end

  @spec run_schedule(state, [Process.t()], scheduler_run_reason, [Event.t()]) ::
          %{state: state, dropped: [Process.t()], paused: [Process.t()]}
  defp run_schedule(state, processes, reason, events) when is_list(processes) do
    {duration, result} = :timer.tc(fn -> do_run_schedule(state, processes, reason) end)

    duration = get_duration(duration)

    case result.state.next do
      {_, time_left, _} ->
        Logger.debug("Scheduled processes in #{duration}; will wake up in #{time_left}ms")

      nil ->
        Logger.debug("Scheduled processes in #{duration}; TOP is empty -- won't wake up")
    end

    events
    |> maybe_filter_out_resume_events(result.paused)
    |> Kernel.++(result.events)
    |> Event.emit_async()

    %{state: result.state, dropped: result.dropped, paused: result.paused}
  end

  @spec do_run_schedule(
          state,
          [Process.t()],
          scheduler_run_reason,
          dropped_processes :: [Process.t()],
          paused_processes :: [Process.t()]
        ) ::
          %{state: state, dropped: [Process.t()], paused: [Process.t()], events: [term]}
  defp do_run_schedule(
         %{server_id: server_id, server_resources: resources} = state,
         processes,
         reason,
         dropped_processes \\ [],
         paused_processes \\ []
       ) do
    with {:ok, allocated_processes} <- TOP.Allocator.allocate(resources, processes),
         now = DateTime.utc_now() |> DateTime.to_unix(:millisecond),
         processes = Enum.map(allocated_processes, &TOP.Scheduler.simulate(&1, now)),
         {:ok, modified_procs} <- TOP.Scheduler.update_modified_processes(server_id, processes),
         process_killed_events = TOP.Scheduler.drop_processes(dropped_processes) do
      top_recalcado_event =
        if reason != :boot or modified_procs > 0 do
          TOPRecalcadoEvent.new(server_id, processes, reason)
        else
          # We don't need to emit the TOPRecalcadoEvent if this TOP just booted and nothing changed
          nil
        end

      case TOP.Scheduler.forecast(processes) do
        {:next, next_process} ->
          now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
          time_left = max(next_process.estimated_completion_ts - now + 10, 0)

          timer_ref =
            case state.next do
              {current_next_process, current_time_left, current_timer_ref} ->
                if current_next_process.id == next_process.id do
                  current_timer_ref
                else
                  cancel_next_timer(current_timer_ref, current_time_left)
                  create_next_timer(time_left)
                end

              nil ->
                create_next_timer(time_left)
            end

          %{
            state: %{state | next: {next_process, time_left, timer_ref}},
            dropped: dropped_processes,
            paused: paused_processes,
            events: [top_recalcado_event | process_killed_events]
          }

        :empty ->
          # TODO: Hibernate? Kill TOP? if empty
          %{
            state: %{state | next: nil},
            dropped: dropped_processes,
            paused: paused_processes,
            events: [top_recalcado_event | process_killed_events]
          }
      end
    else
      {:error, {:overflow, overflowed_resources}} ->
        {new_processes, new_dropped, new_paused} =
          handle_allocation_overflow(state, processes, overflowed_resources, reason)

        do_run_schedule(
          state,
          new_processes,
          reason,
          new_dropped ++ dropped_processes,
          new_paused ++ paused_processes
        )
    end
  end

  defp handle_allocation_overflow(state, processes, overflowed_resources, reason) do
    cond do
      # There was a recent paused process being resumed, which is likely the source of the overflow.
      # Let's just "un-resume" it
      process = find_recently_resumed_process(processes, reason) ->
        # This scenario is a bit different. We won't *drop* the process, but rather *pause* it
        {:ok, paused_process, _} = Svc.Process.pause(%{process | status: :running})

        new_processes =
          Enum.map(processes, fn proc ->
            if proc.id == paused_process.id, do: paused_process, else: proc
          end)

        {new_processes, [], [paused_process]}

      # We have an unallocated process, so we'll start by simply dropping it
      process = Enum.find(processes, &is_nil(&1.resources.allocated)) ->
        {processes -- [process], [process], []}

      # We have overflow even though there are not unallocated or recently resumed processes. This
      # is likely due to a recent downgrade in the server resources. Let's just recursively drop the
      # newest processes until the overflow is resolved
      true ->
        dropped_process =
          TOP.Scheduler.find_newest_using_resource(processes, List.first(overflowed_resources))

        # Sanity check: we *have* to drop something; TOP.Scheduler *must* find a process to kill
        true = not is_nil(dropped_process)

        with {next_process, time_left, timer_ref} <- state.next,
             true <- next_process.id == dropped_process.id do
          # If the dropped process is the "next" one to complete, we need to cancel its timer
          cancel_next_timer(timer_ref, time_left)
        end

        {processes -- [dropped_process], [dropped_process], []}
    end
  end

  defp find_recently_resumed_process(processes, {:resume, resumed_process_id}),
    do: Enum.find(processes, &(&1.id == resumed_process_id))

  defp find_recently_resumed_process(_, _),
    do: nil

  defp maybe_filter_out_resume_events(events, []), do: events

  defp maybe_filter_out_resume_events(events, paused_processes) do
    Enum.reduce(events, [], fn
      %{name: :process_resumed, data: %{process: %{id: resumed_process_id}}} = event, acc ->
        # If the process we just resumed was "re-paused", then drop the ProcessResumedEvent
        if not Enum.any?(paused_processes, &(&1.id == resumed_process_id)) do
          [event | acc]
        else
          acc
        end

      event, acc ->
        [event | acc]
    end)
  end

  defp create_next_timer(time_left) do
    Elixir.Process.send_after(self(), :next_process_completed, time_left)
  end

  defp cancel_next_timer(timer_ref, time_left) do
    # The cancelation may be async if the timer won't complete any time soon
    async? = time_left > 50
    Elixir.Process.cancel_timer(timer_ref, async: async?, info: false)
  end

  defp refetch_process!(%Process{id: process_id, server_id: server_id}) do
    Core.with_context(:server, server_id, :read, fn ->
      Svc.Process.fetch!(by_id: process_id)
    end)
  end

  defp with_registry(key) do
    {:via, Registry, {TOP.Registry.name(), key}}
  end

  defp get_duration(d) when d < 1000, do: "#{d}μs"
  defp get_duration(d) when d < 10_000, do: "#{Float.round(d / 1000, 2)}ms"
  defp get_duration(d) when d < 100_000, do: "#{Float.round(d / 1000, 1)}ms"
  defp get_duration(d), do: "#{trunc(d / 1000)}ms"
end
