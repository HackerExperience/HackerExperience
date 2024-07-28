defmodule Test.Setup.Shared do
  alias Test.Setup
  alias DBLite, as: DB

  def with_lobby_db(%{shard_id: shard_id, db_context: :lobby}) do
    DB.begin(:lobby, shard_id, :write)
    :ok
  end

  def with_lobby_db_readonly(%{shard_id: shard_id, db_context: :lobby}) do
    DB.begin(:lobby, shard_id, :read)
    :ok
  end

  def with_lobby_user(_) do
    {:ok, %{user: Setup.company()}}
  end
end
