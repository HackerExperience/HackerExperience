defmodule Game.Process.TOP do
  @moduledoc """
  The Table Of Processes (TOP) is responsible for recalculating the processes completion date, as
  well as handling process signaling.

  It is a per-Server GenServer. Each (game) Server with active processes have their own (and only)
  instance of the TOP.
  """

  use GenServer

  alias Feeb.DB
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

    data = %{
      server_id: server_id,
      processes: nil
    }

    {:ok, data, {:continue, :bootstrap}}
  end

  def handle_continue(:bootstrap, state) do
    # Here we fetch every process in said server
    processes =
      Core.with_context(:server, state.server_id, :read, fn ->
        DB.all(Game.Process)
      end)

    {:noreply, %{state | processes: processes}}
  end

  defp with_registry(key) do
    {:via, Registry, {TOP.Registry.name(), key}}
  end
end
