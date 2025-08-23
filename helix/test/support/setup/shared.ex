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

  def with_game_webserver(%{shard_id: shard_id, db_context: db_context}) do
    webserver_url =
      case db_context do
        :singleplayer -> "http://localhost:5001/v1"
        :multiplayer -> "http://localhost:5002/v1"
      end

    Process.put(:test_http_client_base_url, webserver_url)

    # Now let's setup a sample Player and JWT so tests don't need to manually create it
    player = Setup.player!()

    # When generating the JWT, we commit the transaction and re-start it because this process is
    # slow (takes 1s). We don't want to block DB transactions for that long (in prod, mostly).
    # In order to not have different `feebdb_repo_timeout` settings for tests, let's do the same
    # here and ensure the token generation does not affect the default repo timeout
    DB.commit()
    jwt = Test.Utils.jwt_token(uid: player.external_id)
    DB.begin(db_context, shard_id, :write)

    {:ok, %{player: player, jwt: jwt}}
  end

  def with_lobby_webserver(_) do
    Process.put(:test_http_client_base_url, "http://localhost:5000/v1")
    :ok
  end

  # Events

  defdelegate wait_events!(opts), to: Test.Event
  defdelegate wait_events_on_server!(server_id, event_name, count \\ 1), to: Test.Event
  defdelegate wait_process_completed_event!(process_id), to: Test.Event
  defdelegate refute_events!(opts), to: Test.Event
  defdelegate refute_events_on_server!(server_id, event_name), to: Test.Event

  # Misc

  def with_lobby_user(_) do
    {:ok, %{user: Setup.lobby_user()}}
  end
end
