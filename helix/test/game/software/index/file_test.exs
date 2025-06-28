defmodule Game.Index.FileTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/2" do
    test "returns all visible files from entity on server" do
      %{server: gateway, entity: entity} = Setup.server()
      %{server: other_server, entity: other_entity} = Setup.server()

      # `entity` has two files visible in `gateway`, while `other_entity` has one
      gtw_file_1 = Setup.file!(gateway.id, visible_by: entity.id)
      gtw_file_2 = Setup.file!(gateway.id, visible_by: entity.id)
      gtw_file_3 = Setup.file!(gateway.id, visible_by: other_entity.id)

      # `entity` has no visible files in `other_server`, while `other_entity` has only one
      other_file_1 = Setup.file!(other_server.id, visible_by: other_entity.id)
      _other_file_2 = Setup.file!(other_server.id)

      # The first two files are found for `entity` on `gateway`
      assert [_, _] = files = Index.File.index(entity.id, gateway.id)
      assert Enum.find(files, &(&1.id == gtw_file_1.id))
      assert Enum.find(files, &(&1.id == gtw_file_2.id))

      # The third file is found for `other_entity` on `gateway`
      assert [file] = Index.File.index(other_entity.id, gateway.id)
      assert file.id == gtw_file_3.id

      # The first "other file" is found for `other_entity` on `other_server`
      assert [file] = Index.File.index(other_entity.id, other_server.id)
      assert file.id == other_file_1.id

      # No files are found for `entity` on `other_server`
      assert [] == Index.File.index(entity.id, other_server.id)
    end
  end

  describe "render_index/2" do
    test "output conforms to the Norm contract" do
      %{server: gateway, entity: entity} = Setup.server()

      # `entity` has two files visible in `gateway`
      Setup.file!(gateway.id, visible_by: entity.id)
      Setup.file!(gateway.id, visible_by: entity.id)

      rendered_index =
        entity.id
        |> Index.File.index(gateway.id)
        |> Index.File.render_index(entity.id)

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = validate_spec(rendered_index, Norm.coll_of(Index.File.spec()))
    end
  end
end
