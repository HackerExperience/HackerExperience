defmodule Game.ConnectionGroupTest do
  use Test.DBCase, async: true
  alias Game.ConnectionGroup

  setup [:with_game_db]

  describe "new/1" do
    test "creates a ConnectionGroup" do
      source_server = Setup.server_lite!()
      %{nip: source_nip} = Setup.network_connection!(source_server.id)

      target_server = Setup.server_lite!()
      %{nip: target_nip} = Setup.network_connection!(target_server.id)

      tunnel = Setup.tunnel_lite!(source_nip: source_nip, target_nip: target_nip)

      assert {:ok, conn_group} =
               %{
                 tunnel_id: tunnel.id,
                 group_type: :ssh
               }
               |> ConnectionGroup.new()
               |> DB.insert()

      assert conn_group.tunnel_id == tunnel.id
      assert conn_group.group_type == :ssh
      assert conn_group.inserted_at
    end
  end
end
