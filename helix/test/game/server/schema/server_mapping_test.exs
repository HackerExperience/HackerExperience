defmodule Game.ServerMappingTest do
  use Test.DBCase, async: true
  alias Feeb.DB
  alias Game.ServerMapping

  setup [:with_game_db]

  describe "foreign keys" do
    @tag capture_log: true
    test "can't insert a ServerMapping without a corresponding Entity" do
      assert {:error, reason} =
               %{entity_id: 1}
               |> ServerMapping.new()
               |> DB.insert()

      assert reason =~ "FOREIGN KEY constraint failed"
    end

    test "`server_mappings.id` is foreign key of `entities.id`" do
      assert [[_, _, parent_table, child_column, parent_column, on_update, on_delete, _]] =
               DB.raw!("pragma foreign_key_list(server_mappings)")

      assert parent_table == "entities"
      assert parent_column == "id"
      assert child_column == "entity_id"
      assert on_update == "RESTRICT"
      assert on_delete == "RESTRICT"
    end
  end
end
