defmodule Game.Endpoint.Server.LoginTest do
  use Test.WebCase, async: true
  alias Core.{ID, NIP}
  alias Game.{Log, LogVisibility, Tunnel, TunnelLink}

  setup [:with_game_db, :with_game_webserver]

  describe "Server.Login request" do
    test "successfully logs into the endpoint (direct connection)", %{shard_id: shard_id} = ctx do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full()
      DB.commit()

      params = %{}
      U.start_sse_listener(ctx, player)

      assert {:ok, %{status: 200, data: %{}}} =
               post(build_path(gtw_nip, endp_nip), params, shard_id: shard_id, token: jwt)

      # A wild Tunnel appears
      begin_game_db()
      assert [tunnel] = DB.all(Tunnel)

      # It has the expected data
      assert tunnel.source_nip == gtw_nip
      assert tunnel.target_nip == endp_nip
      assert tunnel.status == :open
      assert tunnel.access == :ssh

      # TunnelLinks are there, too
      assert [gtw_link, endp_link] =
               DB.all(TunnelLink)
               |> Enum.sort_by(& &1.idx)

      assert gtw_link.tunnel_id == tunnel.id
      assert gtw_link.nip == gtw_nip
      assert gtw_link.idx == 0

      assert endp_link.tunnel_id == tunnel.id
      assert endp_link.nip == endp_nip
      assert endp_link.idx == 1

      # SSH ConnectionGroup was created
      assert [group] = DB.all(Game.ConnectionGroup)
      assert group.tunnel_id == tunnel.id
      assert group.type == :ssh

      # SSH Connections were created
      assert [gtw_conn, endp_conn] =
               DB.all(Game.Connection)
               |> Enum.sort_by(& &1.id)

      assert gtw_conn.nip == gtw_nip
      assert gtw_conn.from_nip == nil
      assert gtw_conn.to_nip == endp_nip
      assert gtw_conn.type == :ssh
      assert gtw_conn.group_id == group.id
      assert gtw_conn.tunnel_id == tunnel.id

      assert endp_conn.nip == endp_nip
      assert endp_conn.from_nip == gtw_nip
      assert endp_conn.to_nip == nil
      assert endp_conn.type == :ssh
      assert endp_conn.group_id == group.id
      assert endp_conn.tunnel_id == tunnel.id

      receive do
        {:event, event} ->
          # The client received a `tunnel_created` event
          assert event.name == "tunnel_created"

          # TODO: Maybe I could have an `assert_id`?
          # Which has the expected data
          assert event.data.tunnel_id == tunnel.id.id
          assert event.data.source_nip == gtw_nip |> NIP.to_external()
          assert event.data.target_nip == endp_nip |> NIP.to_external()
          assert event.data.access == "ssh"
      after
        1000 ->
          flunk("No event received")
      end
    end

    test "successfully logs into the endpoint (using tunnel)", %{shard_id: shard_id} = ctx do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full()

      %{nip: other_hop_nip} = Setup.server_full()
      %{nip: other_endp_nip} = Setup.server_full()

      # Tunnel between Gateway and OtherEndpoint, which we'll use to create an implicit bounce.
      # Notice it has one intermediary hop. Therefore, we expect the final bounce to be:
      # Gateway -> OtherHop -> OtherEndpoint -> Endpoint
      other_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: other_endp_nip, hops: [other_hop_nip])

      DB.commit()

      params =
        %{
          tunnel_id: other_tunnel.id |> ID.to_external()
        }

      U.start_sse_listener(ctx, player)

      assert {:ok, %{status: 200, data: %{}}} =
               post(build_path(gtw_nip, endp_nip), params, shard_id: shard_id, token: jwt)

      receive do
        {:event, %{name: "tunnel_created", data: %{tunnel_id: raw_tunnel_id}}} ->
          begin_game_db(:read)

          # The tunnel was created as expected
          tunnel_id = Tunnel.ID.from_external(raw_tunnel_id)
          tunnel = Svc.Tunnel.fetch(by_id: tunnel_id)
          assert tunnel.source_nip == gtw_nip
          assert tunnel.target_nip == endp_nip
          assert tunnel.status == :open
          assert tunnel.access == :ssh

          # The tunnel has two intermediary hop: `other_hop` -> `other_tunnel`
          # As expected, the final bounce is: Gateway -> OtherHop -> OtherEndpoint -> Endpoint
          [link_gtw, link_hop_1, link_hop_2, link_endp] =
            Svc.Tunnel.list_links(on_tunnel: tunnel.id)

          assert link_gtw.nip == gtw_nip
          assert link_gtw.idx == 0

          assert link_hop_1.nip == other_hop_nip
          assert link_hop_1.idx == 1

          assert link_hop_2.nip == other_endp_nip
          assert link_hop_2.idx == 2

          assert link_endp.nip == endp_nip
          assert link_endp.idx == 3

          # ConnectionGroup was created correctly
          assert [group] =
                   DB.all(Game.ConnectionGroup)
                   |> Enum.filter(&(&1.tunnel_id == tunnel.id))

          assert group.tunnel_id == tunnel.id
          assert group.type == :ssh

          # Proxy connections were created as expected
          assert [gtw_conn, other_hop_conn, other_endpoint_conn] =
                   DB.all(Game.Connection)
                   |> Enum.filter(&(&1.group_id == group.id))
                   |> Enum.filter(&(&1.type == :proxy))
                   |> Enum.sort_by(& &1.id)

          assert gtw_conn.nip == gtw_nip
          assert gtw_conn.from_nip == nil
          assert gtw_conn.to_nip == other_hop_nip
          assert gtw_conn.type == :proxy

          assert other_hop_conn.nip == other_hop_nip
          assert other_hop_conn.from_nip == gtw_nip
          assert other_hop_conn.to_nip == other_endp_nip
          assert other_hop_conn.type == :proxy

          assert other_endpoint_conn.nip == other_endp_nip
          assert other_endpoint_conn.from_nip == other_hop_nip
          assert other_endpoint_conn.to_nip == nil
          assert other_endpoint_conn.type == :proxy

          # Peer connections were created as expected
          assert [src_conn, endp_conn] =
                   DB.all(Game.Connection)
                   |> Enum.filter(&(&1.group_id == group.id))
                   |> Enum.filter(&(&1.type == :ssh))
                   |> Enum.sort_by(& &1.id)

          assert src_conn.nip == other_endp_nip
          assert src_conn.from_nip == nil
          assert src_conn.to_nip == endp_nip

          assert endp_conn.nip == endp_nip
          assert endp_conn.from_nip == other_endp_nip
          assert endp_conn.to_nip == nil
      after
        1000 ->
          flunk("No event received")
      end
    end

    @tag :skip
    test "successfully logs into the endpoint (using VPN)", %{shard_id: _shard_id} = _ctx do
    end

    test "on successful login, log entries are created accordingly", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)
      x_request_id = Random.uuid()

      %{nip: gtw_nip, server: gateway} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip, server: endpoint, entity: endpoint_entity} = Setup.server_full()

      %{nip: other_hop_nip, server: other_hop} = Setup.server_full()
      %{nip: other_endp_nip, server: other_endpoint} = Setup.server_full()

      other_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: other_endp_nip, hops: [other_hop_nip])

      DB.commit()

      # Gateway -> OtherHop -> OtherEndpoint -> Endpoint (because we are using an implicit bounce)
      params =
        %{
          tunnel_id: other_tunnel.id |> ID.to_external()
        }

      assert {:ok, %{status: 200, data: %{}}} =
               post(build_path(gtw_nip, endp_nip), params,
                 shard_id: shard_id,
                 token: jwt,
                 x_request_id: x_request_id
               )

      wait_events!(x_request_id: x_request_id)

      # Gateway -> OtherHop
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :remote_login_gateway
        assert log.data.nip == other_hop_nip
      end)

      # OtherHop (AP): Gateway -> OtherEndpoint
      Core.with_context(:server, other_hop.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :connection_proxied
        assert log.data.from_nip == gtw_nip
        assert log.data.to_nip == other_endp_nip
      end)

      # OtherEndpoint (EN): OtherHop -> Endpoint
      Core.with_context(:server, other_endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :connection_proxied
        assert log.data.from_nip == other_hop_nip
        assert log.data.to_nip == endp_nip
      end)

      # OtherHop -> Endpoint
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :remote_login_endpoint
        assert log.data.nip == other_endp_nip
      end)

      # `player` has visibility on all four logs
      Core.with_context(:player, player.id, :read, fn ->
        visibilities =
          DB.all(LogVisibility)
          |> Enum.map(& &1.server_id)

        assert gateway.id in visibilities
        assert other_hop.id in visibilities
        assert other_endpoint.id in visibilities
        assert endpoint.id in visibilities
      end)

      # `endpoint_entity` does not have visibility on any logs
      Core.with_context(:player, endpoint_entity.id, :read, fn ->
        assert [] == DB.all(LogVisibility)
      end)
    end

    test "can't connect if the endpoint NIP does not exist", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      endp_nip = Map.put(gtw_nip, :ip, Random.ip())
      DB.commit()

      # We can't create the Gateway -> Endpoint connection because Endpoint does not exist
      assert {:error, %{status: 400, error: %{msg: "route_unreachable"}}} =
               post(build_path(gtw_nip, endp_nip), %{}, shard_id: shard_id, token: jwt)
    end

    @tag :skip
    test "can't connect with an incorrect password", %{shard_id: _shard_id} do
    end

    test "can't use someone else's server as gateway", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: other_server, nip: other_nip} = Setup.server_full()
      %{nip: endp_nip} = Setup.server_full()
      DB.commit()

      # The `other_server` belongs to a different user entirely
      refute other_server.entity_id.id == player.id

      # We can't create an OtherServer -> Endpoint connection because OtherServer is not a valid
      # gateway for `player`
      assert {:error, %{status: 400, error: %{msg: "invalid_gateway"}}} =
               post(build_path(other_nip, endp_nip), %{}, shard_id: shard_id, token: jwt)
    end

    test "can't connect to the same server", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: nip} = Setup.server_full(entity_id: player.id)
      DB.commit()

      # We can't connect to the same server
      assert {:error, %{status: 400, error: %{msg: "self_connection"}}} =
               post(build_path(nip, nip), %{}, shard_id: shard_id, token: jwt)
    end

    test "can't connect to another of the player's own gateway", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_1_nip} = Setup.server_full(entity_id: player.id)
      %{nip: gtw_2_nip} = Setup.server_full(entity_id: player.id)
      DB.commit()

      # We can't create an SSH connection to a server that is also owned by us
      assert {:error, %{status: 400, error: %{msg: "self_connection"}}} =
               post(build_path(gtw_1_nip, gtw_2_nip), %{}, shard_id: shard_id, token: jwt)
    end

    @tag :skip
    test "can't connect if one of the VPN NIPs no longer exist", %{shard_id: _shard_id} do
    end

    @tag :skip
    test "can't use another of player's own gateway as part of the bounce", %{shard_id: _shard_id} do
    end

    @tag :skip
    test "can't connect with cycles in the route", %{shard_id: _shard_id} do
    end

    test "fails if tunnel does not exist", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: nip} = Setup.server_full(entity_id: player.id)
      DB.commit()

      params = %{tunnel_id: Random.int()}

      # We can't create an SSH connection using a Tunnel that does not exist
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(nip, nip), params, shard_id: shard_id, token: jwt)
    end

    test "fails if tunnel belongs to someone else", %{shard_id: shard_id} do
      player = Setup.player!()
      other_player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full(entity_id: other_player.id)
      %{nip: other_nip} = Setup.server_full()

      # There is a tunnel from Endpoint -> Other that belongs to OtherPlayer
      other_tunnel = Setup.tunnel!(source_nip: endp_nip, target_nip: other_nip)
      DB.commit()

      params = %{tunnel_id: other_tunnel.id |> ID.to_external()}

      # We can't create an SSH connection using a Tunnel that is not ours
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_authorized"}}} =
               post(build_path(gtw_nip, endp_nip), params, shard_id: shard_id, token: jwt)
    end

    @tag skip: true
    test "fails if tunnel is closed", %{shard_id: _shard_id} do
      # Implement once you support closing Tunnels
    end

    test "fails if tunnel is in a different gateway", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # Player has 2 gateways
      %{nip: gtw_1_nip} = Setup.server_full(entity_id: player.id)
      %{nip: gtw_2_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full()
      %{nip: other_nip} = Setup.server_full()

      # Tunnel is from Gateway2 -> Other
      tunnel = Setup.tunnel!(source_nip: gtw_2_nip, target_nip: other_nip)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external()}

      assert {:error, %{status: 400, error: %{msg: "tunnel_not_authorized"}}} =
               post(build_path(gtw_1_nip, endp_nip), params, shard_id: shard_id, token: jwt)
    end

    test "fails if NIPs are invalid", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)
      params = %{}
      DB.commit()

      invalid_nips =
        [
          "",
          "not_an_ip",
          "0@123",
          "0@1.1.1.1%20",
          "%200@1.1.1.1",
          "0@1.1.1.1@0",
          "1.1.1.1",
          "256.50.256.50",
          "128.128.-1.128",
          "1.1"
        ]

      # First round, testing the gateway NIP
      Enum.each(invalid_nips, fn src_nip ->
        assert {:error, %{status: 400, error: %{msg: "invalid_input:nip"}}} =
                 post("/server/#{src_nip}/login/0@2.2.2.2", params, shard_id: shard_id, token: jwt)
      end)

      # Second round, testing the endpoint NIP
      Enum.each(invalid_nips, fn
        "" ->
          :this_will_cause_a_404_out_of_scope

        tgt ->
          assert {:error, %{status: 400, error: %{msg: "invalid_input:target_nip"}}} =
                   post("/server/0@3.3.3.3/login/#{tgt}", params, shard_id: shard_id, token: jwt)
      end)
    end

    test "fails if tunnel_id is invalid", %{shard_id: shard_id} do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)
      DB.commit()

      [
        "",
        "-1",
        "91mid",
        "10%20",
        "1+1",
        "not_an_id"
      ]
      |> Enum.each(fn invalid_tunnel_id ->
        params = %{tunnel_id: invalid_tunnel_id}

        assert {:error, %{status: 400, error: %{msg: "invalid_input"}}} =
                 post("/server/0@1.1.1.1/login/0@2.2.2.2", params, shard_id: shard_id, token: jwt)
      end)
    end
  end

  defp build_path(%NIP{} = source_nip, %NIP{} = target_nip),
    do: "/server/#{NIP.to_external(source_nip)}/login/#{NIP.to_external(target_nip)}"
end
