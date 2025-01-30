defmodule Game.Henforcers.NetworkTest do
  use Test.DBCase, async: true
  alias Core.NIP
  alias Game.Henforcers

  setup [:with_game_db]

  describe "nip_exists?/1" do
    test "succeeds when NIP exists" do
      server = Setup.server_lite!()
      %{nip: nip} = Setup.network_connection!(server.id, ip: "1.2.3.4")

      assert {true, relay} = Henforcers.Network.nip_exists?(nip)
      assert relay.server == server
      assert_relay(relay, [:server])
    end

    test "fails when NIP does not exist" do
      fake_nip = NIP.parse_external!("0@1.1.1.1")
      assert {false, {:nip, :not_found}, %{}} == Henforcers.Network.nip_exists?(fake_nip)
    end
  end

  describe "all_nips_exist?/1" do
    test "succeeds when all NIPs exist" do
      %{server: server1, nip: nip1} = Setup.server_full()
      %{server: server2, nip: nip2} = Setup.server_full()
      %{server: server3, nip: nip3} = Setup.server_full()

      assert {true, relay} = Henforcers.Network.all_nips_exist?([nip1, nip2, nip3])
      assert_relay(relay, [nip1, nip2, nip3])
      assert relay[nip1].server == server1
      assert relay[nip2].server == server2
      assert relay[nip3].server == server3
    end

    test "fails when one of the NIPs don't exist" do
      %{nip: nip1} = Setup.server_full()
      fake_nip = NIP.parse_external!("0@1.1.1.1")

      assert {false, {:nip, :not_found, fake_nip}, %{}} ==
               Henforcers.Network.all_nips_exist?([nip1, fake_nip])
    end
  end

  describe "tunnel_exists/1" do
    test "succeeds when Tunnel exists" do
      %{nip: gtw_nip} = Setup.server_full()
      %{nip: endp_nip} = Setup.server_full()
      tunnel = Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip)

      assert {true, relay} = Henforcers.Network.tunnel_exists?(tunnel.id)
      assert_relay(relay, [:tunnel])
      assert relay.tunnel == tunnel
    end

    test "fails when Tunnel does not exist" do
      fake_tunnel_id = Random.int() |> Game.Tunnel.ID.new()

      assert {false, {:tunnel, :not_found}, %{}} ==
               Henforcers.Network.tunnel_exists?(fake_tunnel_id)
    end
  end

  describe "is_route_reachable?/1" do
    test "succeeds when route is reachable" do
      %{server: server1, nip: nip1} = Setup.server_full()
      %{server: server2, nip: nip2} = Setup.server_full()
      %{server: server3, nip: nip3} = Setup.server_full()

      assert {true, relay} = Henforcers.Network.is_route_reachable?([nip1, nip2, nip3])
      assert_relay(relay, [:nips_servers])

      assert relay.nips_servers[nip1].server == server1
      assert relay.nips_servers[nip2].server == server2
      assert relay.nips_servers[nip3].server == server3
    end

    test "fails when one of the nips don't exist" do
      %{nip: nip1} = Setup.server_full()
      fake_nip = NIP.parse_external!("0@1.1.1.1")

      assert {false, {:route, {:unreachable, {:nip_not_found, fake_nip}}}, %{}} ==
               Henforcers.Network.is_route_reachable?([nip1, fake_nip])
    end

    @tag skip: true
    test "fails when there are cycles in the route" do
    end
  end

  describe "can_resolve_route?/3" do
    @tag skip: true
    test "succeeds when player has HDB access to intermediary hops" do
      # TODO: Waiting for HDB
    end
  end
end
