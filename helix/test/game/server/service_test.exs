defmodule Game.Services.ServerTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "setup/1" do
    setup [:with_random_autoincrement]

    test "creates the server" do
      entity = Setup.entity!()

      # Mapping was correctly created
      assert {:ok, mapping} = Svc.Server.setup(entity)
      assert mapping.entity_id == entity.id

      # Mapping exists in the database
      assert mapping == DB.one({:server_mappings, :fetch}, mapping.server_id)

      # Server shard was created
      server_db_path = DB.Repo.get_path(:server, mapping.server_id)
      assert File.exists?(server_db_path)

      # We can connect to the newly created Server shard
      DB.begin(:server, mapping.server_id, :write)

      # TODO: Query S.meta and other seed data
    end
  end
end
