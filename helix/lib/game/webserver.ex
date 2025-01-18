defmodule Game.Webserver do
  defdelegate spec, to: __MODULE__.Spec

  alias Game.Endpoint

  # TODO: Routes should be generated from the Spec
  def routes do
    [
      {"/v1/player/sync", %{handler: Endpoint.Player.Sync, method: :post, sse: true}},
      {"/v1/server/:nip/login/:target_nip", %{handler: Endpoint.Server.Login, method: :post}},
      {"/v1/server/:nip/log/:log_id/edit", %{handler: Endpoint.Log.Edit, method: :post}},
      {"/v1/server/:nip/file/:file_id/install", %{handler: Endpoint.File.Install, method: :post}}
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
      Core.Webserver.Belt.Session,
      Core.Webserver.Belt.SetEventRelay,
      Webserver.Dispatcher,
      Webserver.Belt.SendResponse
    ]
  end
end
