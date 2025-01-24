defmodule Game.Henforcers.ServerTest do
  use Test.DBCase, async: true
  alias Game.Henforcers.Server, as: Henforcer

  setup [:with_game_db]

  describe "has_access?/3" do
    test "succeeds for legit local access (via nip)" do
      %{nip: nip, server: server, entity: entity} = Setup.server()

      assert {true, relay} = Henforcer.has_access?(entity.id, nip, nil)
      assert relay.gateway == server
      assert relay.endpoint == nil
      assert relay.target == server
      assert relay.tunnel == nil
      assert relay.entity == entity
      assert relay.access_type == :local
      assert_relay(relay, [:gateway, :endpoint, :target, :tunnel, :entity, :access_type])
    end

    test "succeeds for legit remote access (via nip)" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      assert {true, relay} = Henforcer.has_access?(entity.id, endp_nip, tunnel.id)
      assert relay.gateway == gateway
      assert relay.endpoint == endpoint
      assert relay.target == endpoint
      assert relay.tunnel == tunnel
      assert relay.entity == entity
      assert relay.access_type == :remote
      assert_relay(relay, [:gateway, :endpoint, :target, :tunnel, :entity, :access_type])
    end

    test "succeeds for legit local access (via server_id)" do
      %{server: server, entity: entity} = Setup.server()

      assert {true, relay} = Henforcer.has_access?(entity.id, server.id, nil)
      assert relay.gateway == server
      assert relay.endpoint == nil
      assert relay.target == server
      assert relay.tunnel == nil
      assert relay.entity == entity
      assert relay.access_type == :local
      assert_relay(relay, [:gateway, :endpoint, :target, :tunnel, :entity, :access_type])
    end

    test "succeeds for legit remote access (via server_id)" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      assert {true, relay} = Henforcer.has_access?(entity.id, endpoint.id, tunnel.id)
      assert relay.gateway == gateway
      assert relay.endpoint == endpoint
      assert relay.target == endpoint
      assert relay.tunnel == tunnel
      assert relay.entity == entity
      assert relay.access_type == :remote
      assert_relay(relay, [:gateway, :endpoint, :target, :tunnel, :entity, :access_type])
    end

    test "fails if local access with someone else's NIP" do
      %{entity: entity} = Setup.server()
      %{nip: other_nip} = Setup.server()

      assert {false, {:server, :not_belongs}, %{}} ==
               Henforcer.has_access?(entity.id, other_nip, nil)
    end

    test "fails if remote access using a closed tunnel" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()

      tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)
        |> Map.put(:status, :closed)

      assert tunnel.status == :closed

      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endp_nip, tunnel)

      # Same error when henforcing access via server_id instead of NIP
      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endpoint.id, tunnel)
    end

    test "fails if remote access using somebody else's tunnel on same endpoint" do
      %{entity: entity} = Setup.server()
      %{nip: other_nip} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # This Tunnel actually exists, but it is from Other -> Endpoint
      tunnel = Setup.tunnel!(source_nip: other_nip, target_nip: endp_nip)

      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endp_nip, tunnel)

      # Same error when henforcing access via server_id instead of NIP
      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endpoint.id, tunnel)
    end

    test "fails if remote access using player's own tunnel to a different endpoint" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: other_nip, server: other_server} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # This Tunnel actually exists, but it is from Gateway -> Other
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: other_nip)

      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endp_nip, tunnel)

      # Same error when henforcing access via server_id instead of NIP
      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcer.has_access?(entity.id, endpoint.id, tunnel)

      # But of course there *is* access from Gateway -> Other
      assert {true, _} = Henforcer.has_access?(entity.id, other_nip, tunnel)
      assert {true, _} = Henforcer.has_access?(entity.id, other_server, tunnel)
    end
  end
end
