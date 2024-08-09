defmodule Game.Webserver.Multiplayer do
  defdelegate spec, to: Game.Webserver
  defdelegate routes, to: Game.Webserver

  def belts do
    Game.Webserver.belts(:multiplayer)
  end
end
