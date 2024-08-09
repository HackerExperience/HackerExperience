defmodule Game.Webserver.Spec do
  @doc """
  DOCME
  """
  def spec do
    %{
      title: "Game API",
      version: "1.0.0",
      endpoints: endpoints(),
      default_responses: default_responses(),
      default_schemas: default_schemas()
    }
  end

  defp endpoints do
    %{
      # TODO: It's Sync, not Login
      {Lobby.Endpoint.User.Login, :post} => %{
        path: "/v1/user/login",
        responses: [200, 400, 401, 422]
      }
    }
  end

  defp default_schemas,
    do: Core.Webserver.Spec.default_schemas()

  defp default_responses,
    do: Core.Webserver.Spec.default_responses()
end
