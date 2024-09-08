defmodule Game.Index.PlayerTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/1" do
    test "it returns the expected data" do
      %{server: mainframe, player: player} = Setup.server()

      index = Index.Player.index(player)

      # Index contains all the expected keys
      Enum.each(expected_keys(), fn key ->
        assert Map.has_key?(index, key)
      end)

      # Keys have the expected values
      assert index.mainframe_id == mainframe.id
    end
  end

  describe "render_index/1" do
    test "it returns the rendered version of the index" do
      %{server: mainframe, player: player} = Setup.server()

      index = Index.Player.index(player)
      rendered_index = Index.Player.render_index(index)

      # For now the `render_index/1` is a no-op, but we'll need to update this test with external ID
      # once it is implemented
      assert rendered_index.mainframe_id == mainframe.id
    end
  end

  defp expected_keys do
    Index.Player.output_spec().schema.specs
    |> Map.keys()
    |> Enum.reject(fn key -> key in [:__openapi_name] end)
  end
end
