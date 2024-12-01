defmodule Game.Webserver.Spec do
  alias Game.Endpoint

  @doc """
  DOCME
  """
  def spec do
    %{
      type: :webserver_request,
      title: "Game API",
      version: "1.0.0",
      endpoints: endpoints(),
      default_responses: default_responses(),
      default_schemas: default_schemas()
    }
  end

  defp endpoints do
    %{
      {Endpoint.Player.Sync, :post} => %{
        # TODO: How do I turn this into an SSE spec?
        path: "/v1/player/sync",
        responses: [200, 400]
      },
      {Endpoint.Server.Login, :post} => %{
        path: "/v1/server/{nip}/login/{target_nip}",
        responses: [200]
      }
    }
  end

  defp default_schemas,
    do: Core.Webserver.Spec.default_schemas()

  defp default_responses,
    do: Core.Webserver.Spec.default_responses()
end
