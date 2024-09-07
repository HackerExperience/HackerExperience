defmodule Test.SetupTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  describe "Setup.player/1" do
    test "creates all related data" do
      %{player: player, entity: entity, server: server} = Setup.player()
      assert player.id == entity.id
      assert server.entity_id == entity.id

      # Shards were created
      assert_player_shard(player.id)
      assert_server_shard(server.id)
    end
  end

  describe "Setup.player_lite/1" do
    test "creates lite version (no shards)" do
      %{player: player, entity: entity} = Setup.player_lite()
      assert player.id == entity.id

      # No player shard
      refute_player_shard(player.id)

      # No server entries
      assert [] == Svc.Server.fetch(list_by_entity_id: entity.id)
    end
  end

  describe "Setup.entity/1" do
    test "creates all related data" do
      assert %{entity: entity, player: player, server: server} = Setup.entity()
      assert player.id == entity.id
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
      assert entity.id == player.id

      # No player shard
      refute_player_shard(player.id)

      # No server entries
      assert [] == Svc.Server.fetch(list_by_entity_id: entity.id)
    end
  end

  describe "Setup.server/1" do
    test "creates all related data" do
      assert %{entity: entity, player: player, server: server} = Setup.server()
      assert player.id == entity.id
      assert server.entity_id == entity.id

      # Shards were created
      assert_player_shard(player.id)
      assert_server_shard(server.id)
    end

    test "respects the `entity`/`entity_id` opt" do
      entity = Setup.entity_lite!()
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
      assert player.id == entity.id
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

  defp assert_player_shard(player_id) do
    player_db_path = DB.Repo.get_path(:player, player_id)
    assert File.exists?(player_db_path)
  end

  defp refute_player_shard(player_id) do
    player_db_path = DB.Repo.get_path(:player, player_id)
    refute File.exists?(player_db_path)
  end

  defp assert_server_shard(server_id) do
    server_db_path = DB.Repo.get_path(:server, server_id)
    assert File.exists?(server_db_path)
  end

  defp refute_server_shard(server_id) do
    server_db_path = DB.Repo.get_path(:server, server_id)
    refute File.exists?(server_db_path)
  end
end
