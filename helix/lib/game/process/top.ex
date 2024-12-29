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
  alias Game.Services, as: Svc
  alias Game.Process.Resources
  alias Game.{ProcessRegistry, Server}
  alias __MODULE__

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

    Process.put(:helix_universe, nil)
    Process.put(:helix_universe_shard_id, nil)

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
      name: with_registry({helix_universe, helix_universe_shard_id, raw_id})
    )
  end

  # GenServer API

  def init({universe, universe_shard_id, server_id}) do
    # PS: shard_id may not be necessary here, but overall I think it's better to relay the full ctx
    Process.put(:helix_universe, universe)
    Process.put(:helix_universe_shard_id, universe_shard_id)

    # TODO: Gather this data from S_meta.resources
    server_resources =
      %{cpu: 100_000, ram: 500}
      |> Resources.from_map()

    data = %{
      server_id: server_id,
      server_resources: server_resources,
      next: nil
    }

    {:ok, data, {:continue, :bootstrap}}
  end

  def handle_continue(:bootstrap, state) do
    # Here we fetch every process in said server
    processes =
      Core.with_context(:server, state.server_id, :read, fn ->
        DB.all(Game.Process)
      end)

    schedule(state, processes)
  end

  def handle_info(:next_process_completed, %{next: {process, _, _}} = state) do
    process =
      Core.with_context(:server, state.server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process.id)
      end)

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    if TOP.Scheduler.is_completed?(process) do
      # The process has reached its target. We can delete it from the database and send SIGTERM
      remaining_processes =
        Core.with_context(:server, state.server_id, :write, fn ->
          # TODO: Move to Svc layer
          DB.delete(process)

          # TODO: Move to Svc layer
          DB.all(Game.Process)
        end)

      Core.with_context(:universe, :write, fn ->
        # This is, of course, TODO. FeebDB needs to support delete based on query (aking to Repo.delete_all)
        process_registry =
          DB.all(ProcessRegistry)
          |> Enum.find(&(&1.server_id == state.server_id && &1.process_id == process.id))

        # TODO: Move to Svc layer
        DB.delete({:processes_registry, :delete}, process_registry, [state.server_id, process.id])
      end)

      schedule(state, remaining_processes)
    else
      # Process hasn't really completed; warn and re-run the scheduler
      raise "TODO"
    end
  end

  defp schedule(state, processes) do
    case :timer.tc(fn -> do_schedule(state, processes) end) do
      {duration, {:ok, {:next, time_left}, new_state}} ->
        duration = get_duration(duration)
        Logger.debug("Scheduled processes in #{duration}; will wake up in #{time_left}ms")
        {:noreply, new_state}

      {duration, {:ok, :empty, new_state}} ->
        duration = get_duration(duration)
        Logger.debug("Scheduled processes in #{duration}; TOP is empty -- won't wake up")
        # TODO: Hibernate? Kill TOP?
        {:noreply, new_state}

      {:error, reason} ->
        raise "TODO"
    end
  end

  defp do_schedule(%{server_id: server_id, server_resources: resources} = state, processes) do
    with {:ok, allocated_processes} <- TOP.Allocator.allocate(server_id, resources, processes),
         now = DateTime.utc_now() |> DateTime.to_unix(:millisecond),
         processes = Enum.map(allocated_processes, &TOP.Scheduler.simulate(&1, now)),
         {:ok, _} <- TOP.Scheduler.update_modified_processes(server_id, processes) do
      case TOP.Scheduler.forecast(processes) do
        {:next, next_process} ->
          now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
          # + 10
          time_left = max(next_process.estimated_completion_ts - now, 0)

          timer_ref = Process.send_after(self(), :next_process_completed, time_left)
          {:ok, {:next, time_left}, %{state | next: {next_process, time_left, timer_ref}}}

        :empty ->
          {:ok, :empty, %{state | next: nil}}
      end
    else
      {:error, {:overflow, _overflowed_resources}} ->
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