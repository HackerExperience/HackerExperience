defmodule Game.Index.ProcessTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/2" do
    test "returns all processes from entity on server" do
      %{server: gateway, entity: entity} = Setup.server()
      %{server: endpoint, entity: other_entity} = Setup.server()

      proc_gtw_1 = Setup.process!(gateway.id, type: :random, entity: entity)
      proc_gtw_2 = Setup.process!(gateway.id, type: :random, entity: entity)

      # `entity` can find both processes on `gateway`
      assert [proc_gtw_2, proc_gtw_1] == Index.Process.index(entity.id, gateway.id)

      # `other_entity` can't see any processes on `gateway`
      assert [] == Index.Process.index(other_entity.id, gateway.id)

      proc_endp = Setup.process!(endpoint.id, type: :random, entity: entity)
      proc_endp_other = Setup.process!(endpoint.id, type: :random, entity: other_entity)

      # `entity` can see `proc_endp` on `endpoint`
      assert [proc_endp] == Index.Process.index(entity.id, endpoint.id)

      # `other_entity` can see its own process too
      assert [proc_endp_other] == Index.Process.index(other_entity.id, endpoint.id)
    end
  end

  describe "render_index/1" do
    test "output conforms to the Norm contract" do
      %{server: gateway, entity: entity} = Setup.server()

      proc_1 = Setup.process!(gateway.id, type: :log_delete)
      proc_2 = Setup.process!(gateway.id, type: :file_install)

      rendered_index =
        entity.id
        |> Index.Process.index(gateway.id)
        |> Index.Process.render_index(entity.id)

      assert [rendered_proc_2, rendered_proc_1] = rendered_index

      assert proc_2.id == rendered_proc_2.id |> U.from_eid(entity.id)
      assert rendered_proc_2.type == "file_install"
      assert rendered_proc_2.data == "{}"

      assert proc_1.id == rendered_proc_1.id |> U.from_eid(entity.id)
      assert rendered_proc_1.type == "log_delete"
      assert rendered_proc_1.data =~ "{\"log_id\":"

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Norm.coll_of(Index.Process.spec()))
    end
  end
end
