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
      fake_nip = NIP.from_external("0@1.1.1.1")
      assert {false, {:nip, :not_found}, %{}} == Henforcers.Network.nip_exists?(fake_nip)
    end
  end
end
