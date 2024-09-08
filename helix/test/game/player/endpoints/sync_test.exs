defmodule Game.Endpoint.Player.SyncTest do
  use Test.WebCase, async: true
  alias HELL.Utils
  alias Core.Session.State.SSEMapping

  @path "/player/sync"

  setup [:with_game_db, :with_game_webserver]

  describe "Player.Sync request" do
    test "creates the player on first sync", %{shard_id: shard_id} do
      # There are no players with this `external_id`
      external_id = Random.uuid()
      refute Svc.Player.fetch(by_external_id: external_id)
      with_random_autoincrement()
      DB.commit()

      jwt = U.jwt_token(uid: external_id)
      make_sse_request_async(jwt, shard_id)

      # The Player exists in the database now
      begin_game_db()
      assert Svc.Player.fetch(by_external_id: external_id)
    end

    test "when player already exists, subscribes to SSE", %{shard_id: shard_id} do
      player = Setup.player!()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      make_sse_request_async(jwt, shard_id)

      # The player shows up as subscribed in the SSEMapping

      # TODO: Util to get `session_id` from JWT
      assert [_] = SSEMapping.get_player_subscriptions(player.external_id)
      assert [_] = SSEMapping.get_player_sessions(player.external_id)
    end

    test "allows player to subscribe to SSE twice with different sessions", %{shard_id: shard_id} do
      player = Setup.player!()
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
      player = Setup.player!()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      # The first request will succeed
      make_sse_request_async(jwt, shard_id)

      # The second request will fail. Because we know it will fail, we can call it synchronously.
      assert {:error, %{error: %{msg: reason}}} = make_sse_request_sync(jwt, shard_id)
      assert reason == "already_subscribed"
    end
  end

  describe "Player.Sync request (E2E with curl)" do
    test "client receives pushed events", %{shard_id: shard_id} = ctx do
      player = Setup.player!()
      DB.commit()

      jwt = U.jwt_token(uid: player.external_id)

      # TODO: URL/port logic should be in a shared module
      port = if ctx.db_context == :singleplayer, do: 5001, else: 5002

      cmd =
        "curl -s -H 'Content-Type: application/json' -H 'test-game-shard-id: #{shard_id}' -N " <>
          "http://localhost:#{port}/v1/player/sync?token=#{jwt}"

      port = Port.open({:spawn, cmd}, [:binary, :use_stdio])

      receive do
        {^port, {:data, sse_payload}} ->
          event =
            sse_payload
            |> String.slice(6..-1//1)
            |> String.replace("\n\n", "")
            |> :json.decode()
            |> Utils.Map.atomify_keys()

          assert event.name == "index_requested"
          assert Map.has_key?(event.data, :player)
      after
        5000 ->
          raise "No output from curl"
      end
    end
  end

  defp make_sse_request_async(jwt, shard_id) do
    http_client_base_url = Process.get(:test_http_client_base_url)
    x_request_id = Random.uuid()

    spawn(fn ->
      # Inherit process environment needed by test utils
      Process.put(:test_http_client_base_url, http_client_base_url)

      # We need to run the request in another thread because, since it's an SSE request,
      # it will block indefinitely.
      make_sse_request_sync(jwt, shard_id, x_request_id)
    end)

    # This is a hack for the async nature of SSE requests. A successful SSE request will block
    # indefinitely. For these tests, we want the test to proceed once we know the SSE connection has
    # been established. We know that's the case once the outgoing events generated within the Sync
    # request are emitted and fully processed, which is what `wait_events` ensures! As a result,
    # once `wait_events/1` returns, we know the SSE process is ready and we can proceed testing.
    wait_events(x_request_id: x_request_id)
  end

  defp make_sse_request_sync(jwt, shard_id, x_request_id \\ nil) do
    params = %{token: jwt}
    get(@path, params, shard_id: shard_id, x_request_id: x_request_id)
  end
end
