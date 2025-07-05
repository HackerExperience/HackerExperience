defmodule Game.Index.SoftwareTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/0" do
    test "returns the expected data" do
      index = Index.Software.index()
      assert index.manifest
    end
  end

  describe "render_index/0" do
    test "returns the rendered manifest" do
      index = Index.Software.index()
      rendered_index = Index.Software.render_index(index)

      # Let's grab Cracker as example
      assert cracker = Enum.find(rendered_index.manifest, &(&1.type == "cracker"))
      assert cracker.type == "cracker"
      assert cracker.extension == "crc"
      assert cracker.config.appstore.price == 0

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Core.Spec.validate_spec(rendered_index, Index.Software.output_spec())
    end
  end
end
