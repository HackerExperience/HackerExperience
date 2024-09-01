defmodule Test.Setup.Shared do
  @moduledoc """
  These functions are imported in every test module.
  """

  alias Test.Setup
  alias Feeb.DB

  # DB

  def with_game_db(%{shard_id: shard_id, db_context: db_context}) do
    Process.put(:db_context_for_this_test, db_context)
    Process.put(:shard_id_for_this_test, shard_id)
    DB.begin(db_context, shard_id, :write)
    :ok
  end

  def with_game_db_readonly(%{shard_id: shard_id, db_context: db_context}) do
    DB.begin(db_context, shard_id, :read)
    :ok
  end

  def begin_game_db(access_type \\ :write) do
    db_context = Process.get(:db_context_for_this_test)
    shard_id = Process.get(:shard_id_for_this_test)
    DB.begin(db_context, shard_id, access_type)
  end

  def with_lobby_db(%{shard_id: shard_id, db_context: :lobby}) do
    DB.begin(:lobby, shard_id, :write)
    :ok
  end

  def with_lobby_db_readonly(%{shard_id: shard_id, db_context: :lobby}) do
    DB.begin(:lobby, shard_id, :read)
    :ok
  end

  defdelegate with_random_autoincrement(opts \\ []), to: Test.DB

  # Webserver

  def with_game_webserver(%{db_context: db_context}) do
    webserver_url =
      case db_context do
        :singleplayer -> "http://localhost:5001/v1"
        :multiplayer -> "http://localhost:5002/v1"
      end

    Process.put(:test_http_client_base_url, webserver_url)
    :ok
  end

  def with_lobby_webserver(_) do
    Process.put(:test_http_client_base_url, "http://localhost:5000/v1")
    :ok
  end

  # Events

  defdelegate wait_events(opts), to: Test.Event

  # Misc

  def with_lobby_user(_) do
    {:ok, %{user: Setup.lobby_user()}}
  end
end
