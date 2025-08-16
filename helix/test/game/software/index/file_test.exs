defmodule Game.Index.FileTest do
  use Test.DBCase, async: true
  alias Game.Index
  alias Game.Installation

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
      assert [{file_1, nil}, {file_2, nil}] =
               Index.File.index(entity.id, gateway.id, []) |> Enum.sort()

      assert file_1.id == gtw_file_1.id
      assert file_2.id == gtw_file_2.id

      # The third file is found for `other_entity` on `gateway`
      assert [{file, nil}] = Index.File.index(other_entity.id, gateway.id, [])
      assert file.id == gtw_file_3.id

      # The first "other file" is found for `other_entity` on `other_server`
      assert [{file, nil}] = Index.File.index(other_entity.id, other_server.id, [])
      assert file.id == other_file_1.id

      # No files are found for `entity` on `other_server`
      assert [] == Index.File.index(entity.id, other_server.id, [])
    end

    test "includes installation id when file is installed" do
      %{server: gateway, entity: entity} = Setup.server()

      # `file_1` is installed, `file_2` isn't.
      file_1 = Setup.file!(gateway.id, visible_by: entity.id, installed?: true)
      file_2 = Setup.file!(gateway.id, visible_by: entity.id)

      # Grab all installations
      installations =
        Core.with_context(:server, gateway.id, :read, fn ->
          DB.all(Installation)
        end)

      # There is only one installation (covering `file_1`)
      [installation] = installations
      assert installation.file_id == file_1.id

      assert [{idx_file_1, installation_id}, {idx_file_2, nil}] =
               Index.File.index(entity.id, gateway.id, installations) |> Enum.sort()

      # `file_1` returned alongside its installation
      assert idx_file_1.id == file_1.id
      assert installation_id == installation.id

      # `file_2` returned with no installation
      assert idx_file_2.id == file_2.id
    end
  end

  describe "render_index/2" do
    test "output conforms to the Norm contract" do
      %{server: gateway, entity: entity} = Setup.server()

      # `entity` has two files visible in `gateway`, one of them is installed
      file_1 = Setup.file!(gateway.id, visible_by: entity.id, installed?: true)
      file_2 = Setup.file!(gateway.id, visible_by: entity.id)

      # Grab all installations
      [installation] =
        Core.with_context(:server, gateway.id, :read, fn ->
          DB.all(Installation)
        end)

      rendered_index =
        entity.id
        |> Index.File.index(gateway.id, [installation])
        |> Index.File.render_index(entity.id)

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = validate_spec(rendered_index, Norm.coll_of(Index.File.spec()))

      file_1_eid = U.to_eid(file_1.id, entity.id, gateway.id)
      file_2_eid = U.to_eid(file_2.id, entity.id, gateway.id)

      rendered_file_1 = Enum.find(rendered_index, &(&1.id == file_1_eid))
      rendered_file_2 = Enum.find(rendered_index, &(&1.id == file_2_eid))

      # `file_1` rendered as expected
      assert rendered_file_1.name == file_1.name
      assert rendered_file_1.size == file_1.size
      assert rendered_file_1.type == "#{file_1.type}"
      assert rendered_file_1.version == file_1.version
      assert rendered_file_1.path == file_1.path
      assert installation.id == rendered_file_1.installation_id |> U.from_eid(entity.id)

      # `file_2` rendered as expected
      assert rendered_file_2.name == file_2.name
      assert rendered_file_2.size == file_2.size
      assert rendered_file_2.type == "#{file_2.type}"
      assert rendered_file_2.version == file_2.version
      assert rendered_file_2.path == file_2.path
      refute rendered_file_2.installation_id
    end
  end
end
