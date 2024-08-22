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

    test "Elixir modules were eagerly loaded on startup" do
      # See `Helix.Application.wait_until_helix_modules_are_loaded/1` for context
      assert Code.loaded?(Game.Webserver.Hooks)
      assert Code.loaded?(Lobby.Webserver.Hooks)
      assert Code.loaded?(Core.Event.Publishable)
      assert Code.loaded?(Game.Events.Player.IndexRequested.Publishable)
    end
  end
end
