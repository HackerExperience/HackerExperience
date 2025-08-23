defmodule Game.Index.InstallationTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/2" do
    test "returns all installations on server" do
      server = Setup.server!()
      %{installation: installation_1} = Setup.file(server.id, installed?: true)
      %{installation: installation_2} = Setup.file(server.id, installed?: true)

      # The two installations are listed on `gateway`
      assert [_, _] = installations = Index.Installation.index(server.id)
      assert installation_1 in installations
      assert installation_2 in installations
    end
  end

  describe "render_index/2" do
    test "output conforms to the Norm contract" do
      %{server: server, entity: entity} = Setup.server()
      Setup.file(server.id, installed?: true)
      Setup.file(server.id, installed?: true)

      rendered_index =
        server.id
        |> Index.Installation.index()
        |> Index.Installation.render_index(entity.id)

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = validate_spec(rendered_index, Norm.coll_of(Index.Installation.spec()))
    end
  end
end
