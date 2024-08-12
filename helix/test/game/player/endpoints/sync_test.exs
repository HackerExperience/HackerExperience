defmodule Game.Endpoint.Player.SyncTest do
  use Test.WebCase, async: true
  alias HELL.Utils

  @path "/player/sync"

  setup [:with_game_db, :with_game_webserver]

  describe "Player.Sync request" do
    test "creates the player on first sync", %{shard_id: shard_id} = ctx do
      # There are no players with this `external_id`
      external_id = Random.uuid()
      refute Svc.Player.fetch(by_external_id: external_id)
      DB.commit()

      jwt = U.jwt_token(uid: external_id)
      make_sse_request(jwt, shard_id)

      # The Player exists in the database now
      begin_game_db()
      assert Svc.Player.fetch(by_external_id: external_id)
    end

    test "when player already exists, subscribes to SSE", %{shard_id: shard_id} do
      player = Setup.player()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      make_sse_request(jwt, shard_id)
      raise "TODO"
    end
  end

  defp make_sse_request(jwt, shard_id) do
    params = %{token: jwt}
    http_client_base_url = Process.get(:test_http_client_base_url)

    # TODO: Consider possibility of directly using curl for this particular endpoint

    spawn(fn ->
      # Inherit process environment needed by test utils
      Process.put(:test_http_client_base_url, http_client_base_url)

      # We need to run the request in another thread because, since it's an SSE request,
      # it will block indefinitely.
      get(@path, params, shard_id: shard_id)
    end)

    # TODO: I might be able to reduce this if I eagerly load every module on startup first
    # TODO: Check how long I should wait
    :timer.sleep(100)
  end
end
