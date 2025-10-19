defmodule Game.Index.ScannerTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/2" do
    test "returns all instances from entity on server" do
      %{server: server, entity: entity} = Setup.server()
      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      assert Enum.sort(instances) == Enum.sort(Index.Scanner.index(entity.id, server.id))
    end

    test "handles scenario where there are no instances on server" do
      %{server: server, entity: entity} = Setup.server()
      assert [] == Index.Scanner.index(entity.id, server.id)
    end
  end

  describe "render_index/2" do
    test "renders the index according to the Norm contract" do
      %{server: server, entity: entity} = Setup.server()
      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      DB.commit()

      rendered_index =
        entity.id
        |> Index.Scanner.index(server.id)
        |> Index.Scanner.render_index(entity.id)

      assert log_instance = Enum.find(instances, &(&1.type == :log))
      assert rendered_log_instance = Enum.find(rendered_index, &(&1.type == "log"))

      # The instance ID was convereted to an External ID
      assert log_instance.id == rendered_log_instance.id |> U.from_eid(entity.id)

      # The payload matches the expected Norm contract
      assert {:ok, _} = Core.Spec.validate_spec(rendered_index, Norm.coll_of(Index.Scanner.spec()))
    end

    test "handles scenario where there are no instances to render" do
      %{server: server, entity: entity} = Setup.server()

      assert [] ==
               entity.id
               |> Index.Scanner.index(server.id)
               |> Index.Scanner.render_index(entity.id)
    end
  end
end
