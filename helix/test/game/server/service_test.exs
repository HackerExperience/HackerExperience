defmodule Game.Services.ServerTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "setup/1" do
    setup [:with_random_autoincrement]

    test "creates the server" do
      entity = Setup.entity!()

      # Server was correctly created
      assert {:ok, server} = Svc.Server.setup(entity)
      assert server.entity_id == entity.id

      # Server exists in the database
      assert server == DB.one({:servers, :fetch}, server.id)

      # Server shard was created
      server_db_path = DB.Repo.get_path(Core.get_server_context(), server.id)
      assert File.exists?(server_db_path)

      # We can connect to the newly created Server shard
      Core.with_context(:server, server.id, :write, fn ->
        assert [meta] = DB.all(Game.ServerMeta)
        assert meta.id == server.id
        assert meta.entity_id == entity.id
        assert_decimal_eq(meta.resources.cpu, 1000)
        assert_decimal_eq(meta.resources.ram, 128)
      end)

      # Every server is created with a working NetworkConnection over the internet
      assert %_{} = Svc.NetworkConnection.fetch(by_server_id: server.id)
    end
  end

  describe "fetch/2 - by_id" do
    test "returns the server when it exists" do
      server = Setup.server!()
      assert server == Svc.Server.fetch(by_id: server.id)
    end

    test "returns nil when requested id is not found" do
      Setup.server!()
      refute Svc.Server.fetch(by_id: Random.int())
    end
  end

  describe "list/2 - by_entity_id" do
    test "returns corresponding server when they exist" do
      entity = Setup.entity_lite!()

      server_1 = Setup.server_lite!(entity: entity)
      server_2 = Setup.server_lite!(entity: entity)
      _other_server = Setup.server_lite!()

      servers = Svc.Server.list(by_entity_id: entity.id)
      assert Enum.count(servers) == 2
      assert db_server_1 = Enum.find(servers, &(&1.id == server_1.id))
      assert db_server_2 = Enum.find(servers, &(&1.id == server_2.id))
      assert db_server_1.entity_id == entity.id
      assert db_server_2.entity_id == entity.id
    end
  end
end
