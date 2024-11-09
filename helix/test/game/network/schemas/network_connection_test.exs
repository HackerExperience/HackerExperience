defmodule Game.NetworkConnectionTest do
  use Test.DBCase, async: true
  alias Feeb.DB
  alias Game.NetworkConnection

  setup [:with_game_db]

  describe "new/1" do
    test "creates a nip" do
      server = Setup.server_lite!()

      assert {:ok, nc} =
               %{
                 nip: "0@1.2.3.4",
                 server_id: server.id,
                 inserted_at: DateTime.utc_now()
               }
               |> NetworkConnection.new()
               |> DB.insert()

      assert nc.nip.network_id == 0
      assert nc.nip.ip == "1.2.3.4"
      assert nc.server_id == server.id
      assert nc.inserted_at
    end
  end
end
