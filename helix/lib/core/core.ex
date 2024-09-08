defmodule Core do
  alias Feeb.DB

  # TODO: Consider a more specific API, like `begin_universe/1` and `begin_player/2`

  def begin_context(:universe, access_type) do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    shard_id = Process.get(:helix_universe_shard_id) || raise "Universe shard not set"
    DB.begin(universe, shard_id, access_type)
  end

  def begin_context(:player, player_id, access_type) do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    DB.begin(player_ctx(universe), player_id, access_type)
  end

  def begin_context(:server, server_id, access_type) do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    DB.begin(server_ctx(universe), server_id, access_type)
  end

  def get_player_context do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    player_ctx(universe)
  end

  def get_server_context do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    server_ctx(universe)
  end

  # TODO: I'm not yet sure about the with_context/3,4 API...
  def with_context(:universe, access_type, callback) when access_type in [:read, :write] do
    # DB.with_context(fn ->
    begin_context(:universe, access_type)
    result = callback.()
    DB.commit()
    result
    # end)
  end

  def with_context(:player, player_id, access_type, callback) when access_type in [:read, :write] do
    # DB.with_context(fn ->
    begin_context(:player, player_id, access_type)
    result = callback.()
    DB.commit()
    result
    # end)
  end

  def with_context(:server, server_id, access_type, callback) when access_type in [:read, :write] do
    # DB.with_context(fn ->
    begin_context(:server, server_id, access_type)
    result = callback.()
    DB.commit()
    result
    # end)
  end

  defp player_ctx(:singleplayer), do: :sp_player
  defp player_ctx(:multiplayer), do: :mp_player
  defp server_ctx(:singleplayer), do: :sp_server
  defp server_ctx(:multiplayer), do: :mp_server
end
