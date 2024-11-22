defmodule Game.Henforcers.PlayerTest do
  use Test.DBCase, async: true
  alias Game.Henforcers

  setup [:with_game_db]

  describe "player_exists?/1" do
    test "succeeds when Player exists (input=Player.ID)" do
      player = Setup.player_lite!()
      assert {true, %{player: player}} == Henforcers.Player.player_exists?(player.id)
    end

    test "succeeds when Player exists (input=Entity.ID)" do
      %{player: player, entity: entity} = Setup.player()
      assert {true, %{player: player}} == Henforcers.Player.player_exists?(entity.id)
    end
  end
end
