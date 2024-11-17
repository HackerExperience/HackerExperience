defmodule Game.Services.ConnectionTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "create/2" do
    test "creates a connection inside the tunnel (direct)" do
      %{nip: gtw_nip} = Setup.server_full()
      %{nip: endp_nip} = Setup.server_full()

      # This is a direct Tunnel (no bounce)
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # The group was created with the expected data
      assert {:ok, group} = Svc.Connection.create(tunnel.id, :ftp)
      assert group.tunnel_id == tunnel.id
      assert group.type == :ftp

      # Individual connections were created as expected
      assert [gtw_conn, endp_conn] =
               DB.all(Game.Connection)
               |> Enum.filter(&(&1.type == :ftp))
               |> Enum.sort_by(& &1.id)

      assert gtw_conn.nip == gtw_nip
      assert gtw_conn.from_nip == nil
      assert gtw_conn.to_nip == endp_nip
      assert gtw_conn.type == :ftp
      assert gtw_conn.group_id == group.id
      assert gtw_conn.tunnel_id == tunnel.id

      assert endp_conn.nip == endp_nip
      assert endp_conn.from_nip == gtw_nip
      assert endp_conn.to_nip == nil
      assert endp_conn.type == :ftp
      assert endp_conn.group_id == group.id
      assert endp_conn.tunnel_id == tunnel.id
    end

    test "creates a connection inside the tunnel (with bounce)" do
      %{nip: gtw_nip} = Setup.server_full()
      %{nip: ap_nip} = Setup.server_full()
      %{nip: mid_nip} = Setup.server_full()
      %{nip: en_nip} = Setup.server_full()
      %{nip: endp_nip} = Setup.server_full()

      # Tunnel: Gateway -> Access Point -> Mid -> Exit Node -> Endpoint
      tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip, hops: [ap_nip, mid_nip, en_nip])

      # The group was created with the expected data
      assert {:ok, group} = Svc.Connection.create(tunnel.id, :ftp)
      assert group.tunnel_id == tunnel.id
      assert group.type == :ftp

      # Proxy connections were created as expected
      assert [gtw_conn, ap_conn, mid_conn, en_conn] =
               DB.all(Game.Connection)
               |> Enum.filter(&(&1.group_id == group.id))
               |> Enum.filter(&(&1.type == :proxy))
               |> Enum.sort_by(& &1.id)

      assert gtw_conn.nip == gtw_nip
      assert gtw_conn.from_nip == nil
      assert gtw_conn.to_nip == ap_nip
      assert gtw_conn.type == :proxy

      assert ap_conn.nip == ap_nip
      assert ap_conn.from_nip == gtw_nip
      assert ap_conn.to_nip == mid_nip
      assert ap_conn.type == :proxy

      assert mid_conn.nip == mid_nip
      assert mid_conn.from_nip == ap_nip
      assert mid_conn.to_nip == en_nip
      assert mid_conn.type == :proxy

      assert en_conn.nip == en_nip
      assert en_conn.from_nip == mid_nip
      assert en_conn.to_nip == nil
      assert en_conn.type == :proxy

      # Peer connections were created as expected
      assert [src_conn, endp_conn] =
               DB.all(Game.Connection)
               |> Enum.filter(&(&1.group_id == group.id))
               |> Enum.filter(&(&1.type == :ftp))
               |> Enum.sort_by(& &1.id)

      # Notice how the FTP connection essentially originates from the Exit Node, even though the
      # Exit Node did not *actually* made the action (instead, it was manipulated by the Gateway).
      assert src_conn.nip == en_nip
      assert src_conn.from_nip == nil
      assert src_conn.to_nip == endp_nip

      assert endp_conn.nip == endp_nip
      assert endp_conn.from_nip == en_nip
      assert endp_conn.to_nip == nil
    end
  end
end
