defmodule Game.Webserver do
  defdelegate spec, to: __MODULE__.Spec

  alias Game.Endpoint, as: E

  # TODO: Routes should be generated from the Spec
  def routes do
    [
      {"/v1/player/sync", %{handler: E.Player.Sync, method: :post, sse: true}},
      {"/v1/server/:nip/login/:target_nip", %{handler: E.Server.Login, method: :post}},
      {"/v1/server/:nip/log/:log_id/delete", %{handler: E.Log.Delete, method: :post}},
      {"/v1/server/:nip/log/:log_id/edit", %{handler: E.Log.Edit, method: :post}},
      {"/v1/server/:nip/file/:file_id/delete", %{handler: E.File.Delete, method: :post}},
      {"/v1/server/:nip/file/:file_id/install", %{handler: E.File.Install, method: :post}},
      {"/v1/server/:nip/file/:file_id/transfer", %{handler: E.File.Transfer, method: :post}},
      {"/v1/server/:nip/installation/:installation_id/uninstall",
       %{handler: E.Installation.Uninstall, method: :post}}
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
