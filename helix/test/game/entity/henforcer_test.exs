defmodule Game.Henforcers.EntityTest do
  use Test.DBCase, async: true
  alias Game.Henforcers

  setup [:with_game_db]

  describe "entity_exists?/1" do
    test "succeeds when Entity exists" do
      entity = Setup.entity_lite!()
      assert {true, %{entity: entity}} == Henforcers.Entity.entity_exists?(entity.id)
    end

    test "fails when Entity is not found" do
      fake_entity_id = Random.int() |> Game.Entity.ID.from_external()
      assert {false, {:entity, :not_found}, %{}} == Henforcers.Entity.entity_exists?(fake_entity_id)
    end
  end

  describe "is_player?/1" do
    test "succeeds when Entity is player" do
      %{player: player, entity: entity} = Setup.player()
      assert {true, %{player: player}} == Henforcers.Entity.is_player?(entity.id)
    end

    test "fails when Entity does not exist" do
      fake_entity_id = Random.int() |> Game.Entity.ID.from_external()
      assert {false, {:entity, :not_found}, %{}} == Henforcers.Entity.is_player?(fake_entity_id)
    end

    @tag :skip
    test "fails when Entity is not a player" do
      # Currently we only support Player entities
    end
  end
end
