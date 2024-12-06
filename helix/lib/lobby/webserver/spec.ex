defmodule Lobby.Webserver.Spec do
  @doc """
  DOCME
  """
  def spec do
    %{
      type: :webserver_request,
      title: "Lobby API",
      version: "1.0.0",
      endpoints: endpoints(),
      default_responses: default_responses(),
      default_schemas: default_schemas()
    }
  end

  defp endpoints do
    %{
      {Lobby.Endpoint.User.Login, :post} => %{
        path: "/v1/user/login",
        responses: [200, 400, 401, 422],
        public?: true
      },
      {Lobby.Endpoint.User.Register, :post} => %{
        path: "/v1/user/register",
        responses: [200, 400, 422],
        public?: true
      }
    }
  end

  defp default_schemas,
    do: Core.Webserver.Spec.default_schemas()

  defp default_responses,
    do: Core.Webserver.Spec.default_responses()
end
