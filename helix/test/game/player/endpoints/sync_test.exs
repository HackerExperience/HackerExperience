defmodule Game.Endpoint.Player.SyncTest do
  use Test.WebCase, async: true
  alias HELL.Utils
  alias Core.Session.State.SSEMapping

  @path "/player/sync"

  setup [:with_game_db, :with_game_webserver]

  describe "Player.Sync request" do
    test "creates the player on first sync", %{shard_id: shard_id} = ctx do
      # There are no players with this `external_id`
      external_id = Random.uuid()
      refute Svc.Player.fetch(by_external_id: external_id)
      DB.commit()

      jwt = U.jwt_token(uid: external_id)
      make_sse_request_async(jwt, shard_id)

      # The Player exists in the database now
      begin_game_db()
      assert Svc.Player.fetch(by_external_id: external_id)
    end

    test "when player already exists, subscribes to SSE", %{shard_id: shard_id} do
      player = Setup.player()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      make_sse_request_async(jwt, shard_id)

      # The player shows up as subscribed in the SSEMapping

      # TODO: Util to get `session_id` from JWT
      assert [_] = SSEMapping.get_player_subscriptions(player.external_id)
      assert [_] = SSEMapping.get_player_sessions(player.external_id)
    end

    test "allows player to subscribe to SSE twice with different sessions", %{shard_id: shard_id} do
      player = Setup.player()
      DB.commit()

      ts_now = Utils.DateTime.ts_now()

      jwt_1 = U.jwt_token(uid: player.external_id, iat: ts_now - 10)
      jwt_2 = U.jwt_token(uid: player.external_id, iat: ts_now - 20)

      # The first request will succeed
      make_sse_request_async(jwt_1, shard_id)

      # The second request will succeed
      make_sse_request_async(jwt_2, shard_id)

      # There are two registered sessions/subscriptions for this player
      assert [_, _] = SSEMapping.get_player_subscriptions(player.external_id)
      assert [_, _] = SSEMapping.get_player_sessions(player.external_id)
    end

    test "doesn't allow player to subscribe to SSE twice with same session", %{shard_id: shard_id} do
      player = Setup.player()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      # The first request will succeed
      make_sse_request_async(jwt, shard_id)

      # The second request will fail. Because we know it will fail, we can call it synchronously.
      assert {:error, %{error: %{msg: reason}}} = make_sse_request_sync(jwt, shard_id)
      assert reason == "already_subscribed"
    end
  end

  # TODO: Consider possibility of directly using curl for this particular endpoint
  # (including an E2E test)
  defp make_sse_request_async(jwt, shard_id) do
    http_client_base_url = Process.get(:test_http_client_base_url)

    spawn(fn ->
      # Inherit process environment needed by test utils
      Process.put(:test_http_client_base_url, http_client_base_url)

      # We need to run the request in another thread because, since it's an SSE request,
      # it will block indefinitely.
      make_sse_request_sync(jwt, shard_id)
    end)

    # TODO: I might be able to reduce this if I eagerly load every module on startup first
    # TODO: Check how long I should wait
    :timer.sleep(100)
  end

  defp make_sse_request_sync(jwt, shard_id) do
    params = %{token: jwt}
    get(@path, params, shard_id: shard_id)
  end
end