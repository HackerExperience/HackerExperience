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

  describe "is_route_reachable?/1" do
    test "returns true when route is reachable" do
      %{nip: nip1} = Setup.server_full()
      %{nip: nip2} = Setup.server_full()
      %{nip: nip3} = Setup.server_full()

      assert {true, relay} = Henforcers.Network.is_route_reachable?([nip1, nip2, nip3])

      # TODO: Assert the relay here, write test covering other cases (@skip the TODOs)
      IO.inspect(relay)
    end
  end

  describe "can_resolve_route?/3" do
    test "succeeds when player has HDB access to intermediary hops" do
      %{nip: nip1} = Setup.server_full()
      %{nip: nip2} = Setup.server_full()
      %{nip: nip3} = Setup.server_full()

      # TODO: Assert the relay, write tests covering other cases (@skip the TODO ones)
      Henforcers.Network.can_resolve_route?(nip1, nip3, [nip2])
      |> IO.inspect()
    end
  end
end
