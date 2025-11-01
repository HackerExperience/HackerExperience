defmodule Game.Process.Server.LoginTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "success case with direct connection" do
      %{server: gateway, nip: gtw_nip} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()

      process = Setup.process!(gateway.id, type: :server_login, spec: [target_nip: endp_nip])

      # Player is attempting to log in to `endpoint` (`endp_nip`)
      assert process.type == :server_login
      assert process.server_id == gateway.id
      assert process.data.source_nip == gtw_nip
      assert process.data.target_nip == endp_nip

      # It is a direct connection
      refute process.data.tunnel_id
      refute process.data.vpn_id

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # A wild Tunnel appears
      assert [tunnel] = U.get_all_tunnels()

      # It has the expected data
      assert tunnel.source_nip == gtw_nip
      assert tunnel.target_nip == endp_nip
      assert tunnel.status == :open
      assert tunnel.access == :ssh

      # TunnelLinks are there too
      assert [gtw_link, endp_link] = U.get_all_tunnel_links(tunnel)

      assert gtw_link.tunnel_id == tunnel.id
      assert gtw_link.nip == gtw_nip
      assert gtw_link.idx == 0

      assert endp_link.tunnel_id == tunnel.id
      assert endp_link.nip == endp_nip
      assert endp_link.idx == 1

      # SSH ConnectionGroup was created
      assert [group] = U.get_all_connection_groups(tunnel)
      assert group.tunnel_id == tunnel.id
      assert group.type == :ssh

      # The corresponding SSH Connections were created
      assert [gtw_conn, endp_conn] = U.get_all_connections(tunnel)
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

      # The emitted event has the expected data
      assert event.name == :tunnel_created
      assert event.data.entity_id == process.entity_id
      assert event.data.gateway_id == gateway.id
      assert event.data.endpoint_id == endpoint.id
      assert tunnel == event.data.tunnel
    end

    test "success case with tunnel" do
      %{server: gateway, nip: gtw_nip} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()

      %{nip: inner_hop_nip} = Setup.server()
      %{nip: inner_endp_nip} = Setup.server()

      # Tunnel between Gateway and InnerEndpoint, which we'll use to create an implicit bounce.
      # Notice it has one intermediary hop. Therefore, we expect the final bounce to be:
      # Gateway -> InnerHop -> InnerEndpoint -> Endpoint
      inner_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: inner_endp_nip, hops: [inner_hop_nip])

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: inner_tunnel.id]
        )

      # Player is attempting to log in to `endpoint` (`endp_nip`) with an implicit bounce
      assert process.type == :server_login
      assert process.server_id == gateway.id
      assert process.data.source_nip == gtw_nip
      assert process.data.target_nip == endp_nip

      # It is using `inner_tunnel` as origin
      assert process.data.tunnel_id == inner_tunnel.id
      refute process.data.vpn_id

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # A wild Tunnel appears
      assert [_inner_tunnel, tunnel] = U.get_all_tunnels()

      # It has the expected data
      assert tunnel.source_nip == gtw_nip
      assert tunnel.target_nip == endp_nip
      assert tunnel.status == :open
      assert tunnel.access == :ssh

      # TunnelLinks are there too
      assert [gtw_link, link_hop_1, link_hop_2, endp_link] = U.get_all_tunnel_links(tunnel)

      assert gtw_link.nip == gtw_nip
      assert gtw_link.idx == 0

      assert link_hop_1.nip == inner_hop_nip
      assert link_hop_1.idx == 1

      assert link_hop_2.nip == inner_endp_nip
      assert link_hop_2.idx == 2

      assert endp_link.nip == endp_nip
      assert endp_link.idx == 3

      # SSH ConnectionGroup was created
      assert [group] = U.get_all_connection_groups(tunnel)
      assert group.tunnel_id == tunnel.id
      assert group.type == :ssh

      # The corresponding SSH Connections were created (InnerEndpoint -> Endpoint)
      assert [src_conn, endp_conn] = U.get_all_connections(tunnel, :ssh)
      assert src_conn.nip == inner_endp_nip
      assert src_conn.from_nip == nil
      assert src_conn.to_nip == endp_nip
      assert src_conn.type == :ssh

      assert endp_conn.nip == endp_nip
      assert endp_conn.from_nip == inner_endp_nip
      assert endp_conn.to_nip == nil
      assert endp_conn.type == :ssh

      # The corresponding Proxy connections were created (Gateway -> InnerHop -> InnerEndpoint)
      assert [gtw_conn, ap_conn, en_conn] = U.get_all_connections(tunnel, :proxy)
      assert gtw_conn.nip == gtw_nip
      assert gtw_conn.from_nip == nil
      assert gtw_conn.to_nip == inner_hop_nip
      assert gtw_conn.type == :proxy

      assert ap_conn.nip == inner_hop_nip
      assert ap_conn.from_nip == gtw_nip
      assert ap_conn.to_nip == inner_endp_nip
      assert ap_conn.type == :proxy

      assert en_conn.nip == inner_endp_nip
      assert en_conn.from_nip == inner_hop_nip
      assert en_conn.to_nip == nil
      assert en_conn.type == :proxy

      # The emitted event has the expected data
      assert event.name == :tunnel_created
      assert event.data.entity_id == process.entity_id
      assert event.data.gateway_id == gateway.id
      assert event.data.endpoint_id == endpoint.id
      assert tunnel == event.data.tunnel
    end

    @tag :skip
    test "success case with VPN" do
    end

    @tag :capture_log
    test "fails if the endpoint NIP does not exist" do
      %{server: gateway, nip: gtw_nip} = Setup.server()
      endp_nip = Map.put(gtw_nip, :ip, Random.ip())

      process = Setup.process!(gateway.id, type: :server_login, spec: [target_nip: endp_nip])
      DB.commit()

      # Process fails with `"route_unrecheable"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "route_unreachable"
    end

    @tag :skip
    test "fails if the password is incorrect" do
    end

    @tag :capture_log
    test "fails if attempting to connect to the same server (gtw == endp)" do
      %{server: gateway, nip: gtw_nip} = Setup.server()
      process = Setup.process!(gateway.id, type: :server_login, spec: [target_nip: gtw_nip])
      DB.commit()

      # Process fails with `"route_self_connection"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "route_self_connection"
    end

    @tag :capture_log
    test "fails if connecting to another server from the same player" do
      %{server: gtw_1, entity: entity} = Setup.server()
      %{nip: gtw_2_nip} = Setup.server(entity_id: entity.id)
      process = Setup.process!(gtw_1.id, type: :server_login, spec: [target_nip: gtw_2_nip])
      DB.commit()

      # Process fails with `"route_self_connection"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "route_self_connection"
    end

    @tag :skip
    test "can't connect if one of the VPN NIPs no longer exist" do
    end

    @tag :skip
    test "can't use another of player's own gateway as part of the bounce" do
    end

    @tag :skip
    test "can't connect with cycles in the route" do
    end

    @tag :capture_log
    test "fails if tunnel does not exist" do
      %{server: gateway} = Setup.server()
      %{nip: endp_nip} = Setup.server()

      tunnel_id = Game.Tunnel.ID.new(Random.int())

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: tunnel_id]
        )

      DB.commit()

      # Process fails with `"tunnel_not_found"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "tunnel_not_found"
    end

    @tag :capture_log
    test "fails if tunnel belongs to someone else" do
      %{server: gateway} = Setup.server()
      %{nip: endp_nip} = Setup.server()

      %{nip: other_nip} = Setup.server()

      # There is a tunnel from Endpoint -> Other that belongs to OtherPlayer
      other_tunnel = Setup.tunnel!(source_nip: endp_nip, target_nip: other_nip)

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: other_tunnel.id]
        )

      DB.commit()

      # Process fails with `"tunnel_not_found"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "tunnel_not_found"
    end

    @tag :skip
    test "fails if tunnel is closed" do
    end

    @tag :capture_log
    test "fails if tunnel is in a different gateway" do
      # Player has 2 gateways
      %{server: gateway, entity: entity} = Setup.server()
      %{nip: gtw_2_nip} = Setup.server(entity_id: entity.id)
      %{nip: endp_nip} = Setup.server()

      # Tunnel is from Gateway2 -> Endpoint
      tunnel = Setup.tunnel!(source_nip: gtw_2_nip, target_nip: endp_nip)

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: tunnel.id]
        )

      DB.commit()

      # Process fails with `"tunnel_not_found"` error
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :tunnel_create_failed
      assert event.data.reason == "tunnel_not_found"
    end
  end

  describe "E2E" do
    test "on successful login, creates a new tunnel", ctx do
      %{server: gateway, nip: gtw_nip, player: player} = Setup.server()
      %{nip: endp_nip} = Setup.server()

      %{nip: inner_hop_nip} = Setup.server()
      %{nip: inner_endp_nip} = Setup.server()

      # Gateway -> InnerHop -> InnerEndpoint -> Endpoint
      inner_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: inner_endp_nip, hops: [inner_hop_nip])

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: inner_tunnel.id],
          completed?: true
        )

      DB.commit()

      U.start_sse_listener(ctx, player, last_event: :tunnel_created)

      # Complete the Process
      U.simulate_process_completion(process)

      # First the Client is notified about the process being complete
      process_completed = U.wait_sse_event!(:process_completed)
      assert process_completed.data.process_id |> U.from_eid(player.id) == process.id

      # Then he is notified about the tunnel created event
      tunnel_created = U.wait_sse_event!(:tunnel_created)
      assert tunnel_id = tunnel_created.data.tunnel_id |> U.from_eid(player.id)
      assert tunnel_created.data.source_nip == gtw_nip |> NIP.to_external()
      assert tunnel_created.data.target_nip == endp_nip |> NIP.to_external()

      assert [_inner_tunnel, tunnel] = U.get_all_tunnels()
      assert tunnel.id == tunnel_id
    end

    test "on successful login, log entries are created accordingly" do
      %{server: gateway, nip: gtw_nip, player: player} = Setup.server()
      %{server: endpoint, nip: endp_nip, entity: endpoint_entity} = Setup.server()

      %{server: inner_hop, nip: inner_hop_nip} = Setup.server()
      %{server: inner_endpoint, nip: inner_endp_nip} = Setup.server()

      # Gateway -> InnerHop -> InnerEndpoint -> Endpoint
      inner_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: inner_endp_nip, hops: [inner_hop_nip])

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip, tunnel_id: inner_tunnel.id],
          completed?: true
        )

      DB.commit()

      # Complete the Process
      U.simulate_process_completion(process)

      wait_events_on_server!(gateway.id, :tunnel_created)

      # Gateway -> InnerHop
      assert [log] = U.get_all_logs(gateway.id)
      assert log.type == :server_login
      assert log.direction == :to_ap
      assert log.data.nip == inner_hop_nip

      # InnerHop (AP): Gateway -> InnerEndpoint
      assert [log] = U.get_all_logs(inner_hop.id)
      assert log.type == :connection_proxied
      assert log.direction == :hop
      assert log.data.from_nip == gtw_nip
      assert log.data.to_nip == inner_endp_nip

      # InnerEndpoint (EN): InnerHop -> Endpoint
      assert [log] = U.get_all_logs(inner_endpoint.id)
      assert log.type == :connection_proxied
      assert log.direction == :hop
      assert log.data.from_nip == inner_hop_nip
      assert log.data.to_nip == endp_nip

      # InnerHop -> Endpoint
      assert [log] = U.get_all_logs(endpoint.id)
      assert log.type == :server_login
      assert log.direction == :from_en
      assert log.data.nip == inner_endp_nip

      # `player` has visibility on all four logs
      assert [_] = U.get_all_log_visibilities_on_server(player.id, gateway.id)
      assert [_] = U.get_all_log_visibilities_on_server(player.id, inner_hop.id)
      assert [_] = U.get_all_log_visibilities_on_server(player.id, inner_endpoint.id)
      assert [_] = U.get_all_log_visibilities_on_server(player.id, endpoint.id)

      # `endpoint_entity` does not have visibility on any logs
      assert [] == U.get_all_log_visibilities(endpoint_entity.id)
    end

    test "on successful login, scanner instances are created", ctx do
      %{server: gateway, entity: entity, player: player} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()

      process =
        Setup.process!(gateway.id,
          type: :server_login,
          spec: [target_nip: endp_nip],
          completed?: true
        )

      DB.commit()

      # We expect to receive 2 `ScannerInstancesCreated` events: one for the player immediately
      # after the sync, and another for the remote server login (that we are testing here).
      U.start_sse_listener(ctx, player,
        last_event: :scanner_instances_created,
        total_expected_events: 2
      )

      # Complete the Process
      U.simulate_process_completion(process)

      # Disregard the first ScannerInstancesCreated event -- that's for the gateway, and out of
      # scope for this test
      _gateway_scanner_instances_created = U.wait_sse_event!(:scanner_instances_created)

      # This is the Tunnel that got created (we'll assert it against the Instances afterwards)
      tunnel_created_ev = U.wait_sse_event!(:tunnel_created)
      assert tunnel_id = tunnel_created_ev.data.tunnel_id |> U.from_eid(entity.id)

      # At some point the Client will receive the ScannerInstancesCreated event for the Endpoint
      scanner_instances_created_ev = U.wait_sse_event!(:scanner_instances_created)

      assert scanner_instances_created_ev.name == "scanner_instances_created"
      assert scanner_instances_created_ev.data.nip == endp_nip |> NIP.to_external()
      scanner_instances = scanner_instances_created_ev.data.instances

      # Let's make sure each instance can be found in the DB
      Enum.each(scanner_instances, fn %{"id" => instance_eid, "type" => raw_instance_type} ->
        assert instance_id = instance_eid |> U.from_eid(entity.id)
        instance = Svc.Scanner.fetch_instance!(by_id: instance_id)

        assert instance.server_id == endpoint.id
        assert instance.entity_id == entity.id
        assert instance.tunnel_id == tunnel_id
        assert "#{instance.type}" == raw_instance_type
      end)
    end
  end
end
