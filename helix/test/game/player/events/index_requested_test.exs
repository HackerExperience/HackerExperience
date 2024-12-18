defmodule Game.Events.Player.IndexRequestedTest do
  use Test.DBCase, async: true
  alias Game.Events.Player.IndexRequested
  alias Game.Index

  setup [:with_game_db]

  describe "Publishable.generate_payload/1" do
    @tag :capture_log
    test "generates the correct payload" do
      %{entity: entity, player: player} = Setup.server()

      # Generate the event payload
      event = IndexRequested.new(entity.id)
      assert {:ok, payload} = IndexRequested.Publishable.generate_payload(event)

      # The payload contains the Player Index
      assert Map.has_key?(payload, :player)

      # The Player Index has the expected data
      assert payload.player == player |> Index.Player.index() |> Index.Player.render_index()
    end
  end
end
