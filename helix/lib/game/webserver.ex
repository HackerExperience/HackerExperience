defmodule Game.Webserver do
  defdelegate spec, to: __MODULE__.Spec

  # TODO: Routes should be generated from the Spec
  def routes do
    [
      {"/v1/player/sync", %{handler: Game.Endpoint.Player.Sync, method: :post, sse: true}}
    ]
  end

  def belts(env) when env in [:singleplayer, :multiplayer] do
    [
      {Core.Webserver.Belt.Entrypoint, universe: {:game, env}},
      Webserver.Belt.RequestId,
      # TODO: Cors belt should be Core?
      Lobby.Webserver.Belt.HandleCors,
      Webserver.Belt.ReadBody,
      Webserver.Belt.ParseRequestParams,
      # TODO: Contextualization should/could be Core
      Lobby.Webserver.Belt.Contextualization,
      Webserver.Dispatcher,
      Webserver.Belt.SendResponse
    ]
  end
end
