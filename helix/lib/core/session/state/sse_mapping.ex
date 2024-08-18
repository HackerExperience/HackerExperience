defmodule Core.Session.State.SSEMapping do
  @moduledoc """
  The GenServer part of this module is meant to be as simple/dumb as possible, since we don't want
  it to die in order to not lose the ETS table (or have another process inherit it). Instead, this
  module defines the read/write operations and each caller is responsible for calling them from
  their own process.
  """

  use GenServer

  # Public API

  def subscribe(player_eid, session_id, pid) when is_binary(session_id) and is_pid(pid) do
    get_table_name()
    |> :ets.insert({player_eid, {session_id, pid}})
  end

  def is_subscribed?(player_eid, session_id) do
    get_player_sessions(player_eid)
    |> Enum.any?(&(&1 == session_id))
  end

  def get_player_subscriptions(player_eid) do
    get_table_name()
    |> :ets.lookup(player_eid)
    |> Enum.map(fn {_, {_session_id, pid}} -> pid end)
  end

  def get_player_sessions(player_eid) do
    get_table_name()
    |> :ets.lookup(player_eid)
    |> Enum.map(fn {_, {session_id, _pid}} -> session_id end)
  end

  # GenServer

  def start_link(universe) do
    name = Module.concat(__MODULE__, universe)
    GenServer.start_link(__MODULE__, universe, name: name)
  end

  def init(universe) do
    table_name = get_table_name(universe)
    :ets.new(table_name, [:bag, :public, :named_table])
    {:ok, %{universe: universe}}
  end

  # Private

  defp get_table_name do
    universe = Process.get(:helix_universe)
    if is_nil(universe), do: raise("Process var `helix_universe` not set!")
    get_table_name(universe)
  end

  defp get_table_name(universe) when universe in [:singleplayer, :multiplayer],
    do: :"sse_mapping_#{universe}"
end
