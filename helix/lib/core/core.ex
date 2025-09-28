defmodule Core do
  use Docp
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
    universe_shard_id = Process.get(:helix_universe_shard_id)

    if can_reuse_current_context?([:singleplayer, :multiplayer], universe_shard_id, access_type) do
      # Already in the requested context, so do nothing special. Caller is responsible for COMMITing
      callback.()
    else
      DB.with_context(fn ->
        Core.begin_context(:universe, access_type)
        result = callback.()
        DB.commit()
        result
      end)
    end
  end

  def with_context(:server, server_id, access_type, callback) do
    if can_reuse_current_context?([:sp_server, :mp_server], server_id.id, access_type) do
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
    if can_reuse_current_context?([:sp_player, :mp_player], player_id.id, access_type) do
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

  def commit, do: DB.commit()

  def rollback, do: DB.rollback()

  def get_current_context do
    case DB.LocalState.get_current_context() do
      %{context: ctx, access_type: access, shard_id: shard_id} ->
        {ctx, shard_id, access}

      nil ->
        nil
    end
  end

  @doc """
  Upgrades the current connection access mode from :read to :write. No-ops if already :write mode.
  """
  def upgrade_to_write do
    {ctx, shard_id, current_mode} = get_current_context()

    if current_mode == :read do
      :ok = Core.commit()

      domain = ctx_to_domain(ctx)

      if domain == :universe do
        Core.begin_context(:universe, :write)
      else
        Core.begin_context(domain, shard_id, :write)
      end
    else
      :ok
    end
  end

  @docp """
  It is possible than the context we need is already the context we are currently in. That's what
  this function does: it returns `true` if we can reuse the current context, `false` otherwise.

  We can reuse the current context if:
  - It is the same context we want (`expected_contexts`).
  - Its access type is a "superset" of the `expected_access_type`:
    - If we want :read and we are currently in :write, that's okay.
    - If we want :read and we are currently in :read, that's okay.
    - If we want :write and we are currently in :write, that's okay.
    - If we want :write and we are currently in :read, that's NOT okay and we can't re-use it.
  """
  defp can_reuse_current_context?(expected_contexts, expected_shard_id, expected_access_type)
       when is_integer(expected_shard_id) do
    ctx = DB.LocalState.get_current_context()

    cond do
      is_nil(ctx) ->
        false

      ctx.context not in expected_contexts ->
        false

      ctx.shard_id != expected_shard_id ->
        # We can never re-use the context of a different shard
        false

      ctx.access_type == :read and expected_access_type == :write ->
        # Despite being in the same context, we need to upgrade the access type from read to write
        false

      :else ->
        true
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

  def assert_context_server_id!(%Game.Server.ID{id: expected_server_id}) do
    context_id = get_server_id_from_context!()

    if expected_server_id != context_id,
      do: raise("Bad context: expected server_id #{expected_server_id}, got: #{context_id}")
  end

  def get_player_id_from_context! do
    state = DB.LocalState.get_current_context!()
    assert_player_context!(state.context)
    state.shard_id
  end

  def assert_context_player_id!(%Game.Entity.ID{id: expected_player_id}) do
    context_id = get_player_id_from_context!()

    if expected_player_id != context_id,
      do: raise("Bad context: expected player_id #{expected_player_id}, got: #{context_id}")
  end

  defp player_ctx(:singleplayer), do: :sp_player
  defp player_ctx(:multiplayer), do: :mp_player
  defp server_ctx(:singleplayer), do: :sp_server
  defp server_ctx(:multiplayer), do: :mp_server

  defp ctx_to_domain(:singleplayer), do: :universe
  defp ctx_to_domain(:multiplayer), do: :universe
  defp ctx_to_domain(:sp_player), do: :player
  defp ctx_to_domain(:mp_player), do: :player
  defp ctx_to_domain(:sp_server), do: :server
  defp ctx_to_domain(:mp_server), do: :server

  defp to_shard_id(%{id: id}), do: id
  defp to_shard_id(id) when is_integer(id), do: id
end
