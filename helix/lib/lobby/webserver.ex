defmodule Lobby.Webserver do
  defdelegate spec, to: __MODULE__.Spec

  # TODO: Check what the compilation graph looks like, as this is used by config at compile time?
  # TODO: Routes should be generated from the Spec
  def routes do
    [
      {"/v1/user/register", %{handler: Lobby.Endpoint.User.Register, method: :post}},
      {"/v1/user/login", %{handler: Lobby.Endpoint.User.Login, method: :post}}
    ]
  end

  def belts do
    [
      Webserver.Belt.RequestId,
      Lobby.Webserver.Belt.HandleCors,
      Webserver.Belt.ReadBody,
      Webserver.Belt.ParseRequestParams,
      Lobby.Webserver.Belt.Contextualization,
      # TODO: Not liking dispatcher here. Rethink how belts are passed / declared
      Webserver.Dispatcher,
      Webserver.Belt.SendResponse
    ]
  end
end
