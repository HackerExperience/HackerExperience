defmodule Game.ConnectionTest do
  use Test.DBCase, async: true
  alias Game.{Connection, ConnectionGroup}

  setup [:with_game_db]

  describe "new/1" do
    test "creates a Connection" do
      source_server = Setup.server_lite!()
      %{nip: source_nip} = Setup.network_connection!(source_server.id)

      target_server = Setup.server_lite!()
      %{nip: target_nip} = Setup.network_connection!(target_server.id)

      tunnel = Setup.tunnel_lite!(source_nip: source_nip, target_nip: target_nip)

      conn_group =
        %{tunnel_id: tunnel.id, group_type: :ssh}
        |> ConnectionGroup.new()
        |> DB.insert!()

      %{
        nip: source_nip,
        from_nip: nil,
        to_nip: target_nip,
        connection_type: :ssh,
        tunnel_id: tunnel.id,
        group_id: conn_group.id
      }
      |> Connection.new()
      |> DB.insert!()
    end
  end
end
