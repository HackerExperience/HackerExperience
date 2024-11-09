defmodule Game.Services.NetworkTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "create_tunnel/2" do
    test "creates a tunnel" do
      gateway = Setup.server_lite!()
      %{nip: gtw_nip} = Setup.network_connection!(gateway.id, ip: "1.1.1.1")

      access_point = Setup.server_lite!()
      %{nip: ap_nip} = Setup.network_connection!(access_point.id, ip: "2.2.2.2")

      exit_node = Setup.server_lite!()
      %{nip: en_nip} = Setup.network_connection!(exit_node.id, ip: "3.3.3.3")

      endpoint = Setup.server_lite!()
      %{nip: endp_nip} = Setup.network_connection!(endpoint.id, ip: "4.4.4.4")

      parsed_links =
        [
          {gtw_nip, gateway.id},
          {ap_nip, access_point.id},
          {en_nip, exit_node.id},
          {endp_nip, endpoint.id}
        ]

      assert {:ok, tunnel} = Svc.Network.create_tunnel(parsed_links)

      # `Game.Tunnel` was created with the correct data
      assert tunnel.source_nip == gtw_nip
      assert tunnel.target_nip == endp_nip
      assert tunnel.access == :ssh
      assert tunnel.status == :open

      # `Game.TunnelLink`s were created with the correct data
      assert [gtw_link, ap_link, en_link, endp_link] =
               DB.all(Game.TunnelLink)
               |> Enum.sort_by(& &1.idx)

      assert gtw_link.tunnel_id == tunnel.id
      assert gtw_link.idx == 0
      assert gtw_link.nip == gtw_nip

      assert ap_link.tunnel_id == tunnel.id
      assert ap_link.idx == 1
      assert ap_link.nip == ap_nip

      assert en_link.tunnel_id == tunnel.id
      assert en_link.idx == 2
      assert en_link.nip == en_nip

      assert endp_link.tunnel_id == tunnel.id
      assert endp_link.idx == 3
      assert endp_link.nip == endp_nip
    end
  end
end
