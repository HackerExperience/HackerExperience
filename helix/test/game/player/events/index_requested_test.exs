defmodule Game.Events.Player.IndexRequestedTest do
  use Test.DBCase, async: true
  alias Game.Events.Player.IndexRequested
  alias Game.Index

  setup [:with_game_db]

  describe "Publishable.generate_payload/1" do
    test "generates the correct payload" do
      %{entity: entity, player: player} = Setup.server()

      # Generate the event payload
      event = IndexRequested.new(entity.id)
      assert {:ok, payload} = IndexRequested.Publishable.generate_payload(event)

      # The payload contains the Player Index and the Software Index
      assert Map.has_key?(payload, :player)
      assert Map.has_key?(payload, :software)

      # The Player Index has the expected data
      assert payload.player ==
               player |> Index.Player.index() |> Index.Player.render_index(player.id)

      # The Software Index has the expected data
      assert payload.software ==
               Index.Software.index() |> Index.Software.render_index()
    end
  end
end
