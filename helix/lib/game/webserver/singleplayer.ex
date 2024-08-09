defmodule Game.Webserver.Singleplayer do
  defdelegate spec, to: Game.Webserver
  defdelegate routes, to: Game.Webserver

  def belts do
    Game.Webserver.belts(:singleplayer)
  end
end
