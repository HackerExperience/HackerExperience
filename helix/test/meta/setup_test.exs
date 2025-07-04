defmodule Test.SetupTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  describe "Setup.player/1" do
    test "creates all related data" do
      %{player: player, entity: entity, server: server} = Setup.player()
      assert player.id.id == entity.id.id
      assert server.entity_id == entity.id

      # Shards were created
      assert_player_shard(player.id)
      assert_server_shard(server.id)
    end
  end

  describe "Setup.player_lite/1" do
    test "creates lite version (no shards)" do
      with_random_autoincrement()

      %{player: player, entity: entity} = Setup.player_lite()
      assert player.id.id == entity.id.id

      # No player shard
      refute_player_shard(player.id)

      # No server entries
      assert [] == Svc.Server.list(by_entity_id: entity.id)
    end
  end

  describe "Setup.entity/1" do
    test "creates all related data" do
      assert %{entity: entity, player: player, server: server} = Setup.entity()
      assert player.id.id == entity.id.id
      assert server.entity_id == entity.id

      # Shards were created
      assert_player_shard(player.id)
      assert_server_shard(server.id)
    end
  end

  describe "Setup.entity_lite/1" do
    test "creates lite version (no shards)" do
      with_random_autoincrement()

      assert %{entity: entity, player: player} = Setup.entity_lite()
      assert entity.id.id == player.id.id

      # No player shard
      refute_player_shard(player.id)

      # No server entries
      assert [] == Svc.Server.list(by_entity_id: entity.id)
    end
  end

  describe "Setup.server/1" do
    test "creates all related data" do
      assert %{entity: entity, player: player, server: server, meta: meta, nip: nip} =
               Setup.server()

      assert player.id.id == entity.id.id
      assert server.entity_id == entity.id

      # Shards were created
      assert_player_shard(player.id)
      assert_server_shard(server.id)

      # Creates a NetworkConnection for the server
      assert [nc] = DB.all(Game.NetworkConnection)
      assert nc.server_id == server.id
      assert nc.nip == nip

      # Creates the meta entry for the server
      assert meta == Svc.Server.get_meta(server.id)
    end

    test "supports custom resources being specified" do
      %{meta: %{resources: default_initial_resources}} = Setup.server()

      # The "ram" resource was modified, whereas the "cpu" resource remained unchanged
      assert %{meta: meta} = Setup.server(resources: %{ram: 999})
      assert meta.resources.cpu == default_initial_resources.cpu
      assert meta.resources.ram == Decimal.new(999)
      assert meta.resources.__struct__ == Game.Process.Resources
    end

    test "respects the `entity`/`entity_id` opt" do
      entity = Setup.entity!()
      server_1 = Setup.server!(entity: entity)
      server_2 = Setup.server!(entity_id: entity.id)
      assert server_1.entity_id == entity.id
      assert server_2.entity_id == entity.id
    end
  end

  describe "Setup.server_lite/1" do
    test "creates lite version (no shards)" do
      with_random_autoincrement()
      assert %{entity: entity, player: player, server: server} = Setup.server_lite()
      assert player.id.id == entity.id.id
      assert server.entity_id == entity.id

      # No shards were created
      refute_player_shard(player.id)
      refute_server_shard(server.id)
    end

    test "respects the `entity`/`entity_id` opt" do
      entity = Setup.entity_lite!()
      server_1 = Setup.server_lite!(entity: entity)
      server_2 = Setup.server_lite!(entity_id: entity.id)
      assert server_1.entity_id == entity.id
      assert server_2.entity_id == entity.id
    end
  end

  describe "Setup.process/1" do
    test "allows user to modify the process objective" do
      server = Setup.server!()
      process = Setup.process!(server.id, objective: %{cpu: 123})
      assert_decimal_eq(process.resources.objective.cpu, 123)
    end
  end

  defp assert_player_shard(%_{id: player_id}) do
    player_db_path = DB.Repo.get_path(Core.get_player_context(), player_id)
    assert File.exists?(player_db_path)
  end

  defp refute_player_shard(%_{id: player_id}) do
    player_db_path = DB.Repo.get_path(Core.get_player_context(), player_id)
    refute File.exists?(player_db_path)
  end

  defp assert_server_shard(%_{id: server_id}) do
    server_db_path = DB.Repo.get_path(Core.get_server_context(), server_id)
    assert File.exists?(server_db_path)
  end

  defp refute_server_shard(%_{id: server_id}) do
    server_db_path = DB.Repo.get_path(Core.get_server_context(), server_id)
    refute File.exists?(server_db_path)
  end
end
