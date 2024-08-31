defmodule Game.Webserver.Spec do
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
      {Game.Endpoint.Player.Sync, :post} => %{
        # TODO: How do I turn this into an SSE spec?
        path: "/v1/player/sync",
        responses: [200, 400]
      }
    }
  end

  defp default_schemas,
    do: Core.Webserver.Spec.default_schemas()

  defp default_responses,
    do: Core.Webserver.Spec.default_responses()
end
