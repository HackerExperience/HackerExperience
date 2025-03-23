defmodule Game.Index.PlayerTest do
  use Test.DBCase, async: true
  alias Game.Index

  setup [:with_game_db]

  describe "index/1" do
    test "it returns the expected data" do
      %{nip: nip, player: player} = Setup.server()

      index = Index.Player.index(player)

      # Index contains all the expected keys
      Enum.each(expected_keys(), fn key ->
        assert Map.has_key?(index, key)
      end)

      # Keys have the expected values
      assert index.mainframe_nip == nip
    end

    test "index with multiple endpoints" do
      # `entity` has two endpoints: `endp_nip_1` and `endp_nip_2`
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: endp_nip_1} = Setup.server()
      %{nip: endp_nip_2} = Setup.server()
      Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip_1)
      Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip_2)

      assert index = Index.Player.index(entity)

      # Both endpoints were returned in the index
      assert Enum.count(index.endpoints) == 2
      assert endp_1 = Enum.find(index.endpoints, &(&1.nip == endp_nip_1))
      assert endp_1.logs == []
      assert endp_2 = Enum.find(index.endpoints, &(&1.nip == endp_nip_2))
      assert endp_2.logs == []
    end
  end

  describe "render_index/1" do
    test "it returns the rendered version of the index" do
      %{nip: nip, player: player} = Setup.server()

      index = Index.Player.index(player)
      rendered_index = Index.Player.render_index(index, player.id)

      assert rendered_index.mainframe_nip == nip |> NIP.to_external()

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Index.Player.output_spec())
    end
  end

  defp expected_keys do
    Index.Player.output_spec().schema.specs
    |> Map.keys()
    |> Enum.reject(fn key -> key in [:__openapi_name] end)
  end
end
