defmodule Game.Webserver.Singleplayer do
  defdelegate spec, to: Game.Webserver
  defdelegate routes, to: Game.Webserver
  defdelegate belts, to: Game.Webserver
end
