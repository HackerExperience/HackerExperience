defmodule Game.PlayerTest do
  use Test.DBCase, async: true
  alias Feeb.DB
  alias Game.Player

  setup [:with_game_db]

  describe "foreign keys" do
    @tag capture_log: true
    test "can't insert a player without a corresponding entity" do
      assert {:error, reason} =
               Setup.Player.params()
               |> Player.new()
               |> DB.insert()

      assert reason =~ "FOREIGN KEY constraint failed"
    end

    test "`players.id` is foreign key of `entities.id`" do
      assert [[_, _, parent_table, child_column, parent_column, on_update, on_delete, _]] =
               DB.raw!("pragma foreign_key_list(players)")

      assert parent_table == "entities"
      assert parent_column == "id"
      assert child_column == "id"
      assert on_update == "RESTRICT"
      assert on_delete == "RESTRICT"
    end
  end
end
