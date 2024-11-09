defmodule Game.TunnelLinkTest do
  use Test.DBCase, async: true
  alias Game.TunnelLink

  setup [:with_game_db]

  describe "new/1" do
    test "creates a tunnel link" do
      gateway = Setup.server_lite!()
      %{nip: gtw_nip} = Setup.network_connection!(gateway.id, ip: "1.1.1.1")

      endpoint = Setup.server_lite!()
      %{nip: endp_nip} = Setup.network_connection!(endpoint.id, ip: "2.2.2.2")

      # There is a tunnel between `gateway` and `endpoint`
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      assert {:ok, link_1} =
               %{
                 tunnel_id: tunnel.id,
                 idx: 0,
                 nip: gtw_nip
               }
               |> TunnelLink.new()
               |> DB.insert()

      assert {:ok, link_2} =
               %{
                 tunnel_id: tunnel.id,
                 idx: 1,
                 nip: endp_nip
               }
               |> TunnelLink.new()
               |> DB.insert()

      # The first link in this tunnel is `gateway`
      assert link_1.tunnel_id == tunnel.id
      assert link_1.nip == gtw_nip
      assert link_1.idx == 0

      # The second link is `endpoint`
      assert link_2.tunnel_id == tunnel.id
      assert link_2.nip == endp_nip
      assert link_2.idx == 1
    end
  end
end
