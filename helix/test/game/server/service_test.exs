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

  describe "fetch/2 - by_server_id" do
    test "returns the mapping when it exists" do
      mapping = Setup.server!()
      assert mapping == Svc.Server.fetch(by_server_id: mapping.server_id)
    end

    test "returns nil when requested server_id is not found" do
      Setup.server!()
      refute Svc.Server.fetch(by_server_id: Random.int())
    end
  end

  describe "fetch/2 - list_by_entity_id" do
    test "returns corresponding mapping when they exist" do
      entity = Setup.entity_lite!()

      mapping_1 = Setup.server_lite!(entity: entity)
      mapping_2 = Setup.server_lite!(entity: entity)
      _other_mapping = Setup.server_lite!()

      mappings = Svc.Server.fetch(list_by_entity_id: entity.id)
      assert Enum.count(mappings) == 2
      assert db_mapping_1 = Enum.find(mappings, &(&1.server_id == mapping_1.server_id))
      assert db_mapping_2 = Enum.find(mappings, &(&1.server_id == mapping_2.server_id))
      assert db_mapping_1.entity_id == entity.id
      assert db_mapping_2.entity_id == entity.id
    end
  end
end
