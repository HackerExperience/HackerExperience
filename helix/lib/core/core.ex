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
    DB.begin(player_ctx(universe), to_shard_id(player_id), access_type)
  end

  def begin_context(:server, server_id, access_type) do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    DB.begin(server_ctx(universe), to_shard_id(server_id), access_type)
  end

  def get_player_context do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    player_ctx(universe)
  end

  def get_server_context do
    universe = Process.get(:helix_universe) || raise "Universe not set"
    server_ctx(universe)
  end

  @doc """
  Syntactic sugar on top of `DB.with_context/1`:
  - Invoke `DB.with_context/1`
  - Begin a transaction in the shard within the correct universe
  - Commit it
  - Return the result

  If you don't want to commit, use `DB.with_context/1` directly (or add `with_context_no_commit/3`)
  """
  def with_context(:universe, access_type, callback) do
    DB.with_context(fn ->
      Core.begin_context(:universe, access_type)
      result = callback.()
      DB.commit()
      result
    end)
  end

  def with_context(:server, server_id, access_type, callback) do
    ctx = DB.LocalState.get_current_context()

    if ctx && ctx.context in [:sp_server, :mp_server] && ctx.shard_id == server_id.id &&
         ctx.access_type == access_type do
      # Already in the requested context, so do nothing special. Caller is responsible for COMMITing
      callback.()
    else
      DB.with_context(fn ->
        Core.begin_context(:server, server_id, access_type)
        result = callback.()
        DB.commit()
        result
      end)
    end
  end

  def with_context(:player, player_id, access_type, callback) do
    ctx = DB.LocalState.get_current_context()

    if ctx && ctx.context in [:sp_player, :mp_player] && ctx.shard_id == player_id.id &&
         ctx.access_type == access_type do
      # Already in the requested context, so do nothing special. Caller is responsible for COMMITing
      callback.()
    else
      DB.with_context(fn ->
        Core.begin_context(:player, player_id, access_type)
        result = callback.()
        DB.commit()
        result
      end)
    end
  end

  def assert_server_context! do
    DB.LocalState.get_current_context!().context
    |> assert_server_context!()
  end

  def assert_server_context!(ctx) when ctx in [:sp_server, :mp_server], do: :ok
  def assert_server_context!(ctx), do: raise("Invalid context '#{inspect(ctx)}'; expected Server.")

  def assert_player_context! do
    DB.LocalState.get_current_context!().context
    |> assert_player_context!()
  end

  def assert_player_context!(ctx) when ctx in [:sp_player, :mp_player], do: :ok
  def assert_player_context!(ctx), do: raise("Invalid context '#{inspect(ctx)}'; expected Player.")

  def get_server_id_from_context! do
    state = DB.LocalState.get_current_context!()
    assert_server_context!(state.context)
    state.shard_id
  end

  def get_player_id_from_context! do
    state = DB.LocalState.get_current_context!()
    assert_player_context!(state.context)
    state.shard_id
  end

  defp player_ctx(:singleplayer), do: :sp_player
  defp player_ctx(:multiplayer), do: :mp_player
  defp server_ctx(:singleplayer), do: :sp_server
  defp server_ctx(:multiplayer), do: :mp_server

  defp to_shard_id(%{id: id}), do: id
  defp to_shard_id(id) when is_integer(id), do: id
end
