defmodule Game.ServerTest do
  use Test.DBCase, async: true
  alias Feeb.DB
  alias Game.Server

  setup [:with_game_db]

  describe "foreign keys" do
    @tag capture_log: true
    test "can't insert a Server without a corresponding Entity" do
      assert {:error, reason} =
               %{entity_id: 1}
               |> Server.new()
               |> DB.insert()

      assert reason =~ "FOREIGN KEY constraint failed"
    end

    test "`servers.id` is foreign key of `entities.id`" do
      assert [[_, _, parent_table, child_column, parent_column, on_update, on_delete, _]] =
               DB.raw!("pragma foreign_key_list(servers)")

      assert parent_table == "entities"
      assert parent_column == "id"
      assert child_column == "entity_id"
      assert on_update == "RESTRICT"
      assert on_delete == "RESTRICT"
    end
  end

  describe "new/1" do
    test "creates a server" do
      entity = Setup.entity_lite!()

      assert {:ok, server} =
               %{
                 entity_id: entity.id,
                 inserted_at: DateTime.utc_now()
               }
               |> Server.new()
               |> DB.insert()

      assert server.id == %Server.ID{id: 1}
      assert server.entity_id == entity.id
      assert server.inserted_at
    end
  end
end
