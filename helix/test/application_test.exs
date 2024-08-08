defmodule Helix.ApplicationTest do
  use ExUnit.Case, async: true

  describe "Helix Application" do
    test "all expected supervisors are up and running (webserver)" do
      # In the default test environment, we expect three webservers to be running:
      # Lobby.Webserver, Game.Webserver.Singleplayer and Game.Webserver.Multiplayer
      children = Supervisor.which_children(Webserver.Supervisor)

      assert Enum.find(children, fn {mod, _, _, _} -> mod == Lobby.Webserver end)
      assert Enum.find(children, fn {mod, _, _, _} -> mod == Game.Webserver.Singleplayer end)
      assert Enum.find(children, fn {mod, _, _, _} -> mod == Game.Webserver.Multiplayer end)
      assert Enum.count(children) == 3
    end
  end
end
