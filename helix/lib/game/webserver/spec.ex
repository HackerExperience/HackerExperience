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
        responses: [200, 400],
        # SSE apiKey is passed as a parameter. Not really public, but for the OAS it is
        public?: true
      },
      {Endpoint.Server.Login, :post} => %{
        path: "/v1/server/{nip}/login/{target_nip}",
        responses: [200]
      },
      {Endpoint.File.Delete, :post} => %{
        path: "/v1/server/{nip}/file/{file_id}/delete",
        responses: [200]
      },
      {Endpoint.File.Install, :post} => %{
        path: "/v1/server/{nip}/file/{file_id}/install",
        responses: [200]
      },
      {Endpoint.File.Transfer, :post} => %{
        path: "/v1/server/{nip}/file/{file_id}/transfer",
        responses: [200]
      },
      {Endpoint.Installation.Uninstall, :post} => %{
        path: "/v1/server/{nip}/installation/{installation_id}/uninstall",
        responses: [200]
      },
      {Endpoint.Log.Delete, :post} => %{
        path: "/v1/server/{nip}/log/{log_id}/delete",
        responses: [200]
      },
      {Endpoint.Log.Edit, :post} => %{
        path: "/v1/server/{nip}/log/{log_id}/edit",
        responses: [200]
      },
      {Endpoint.Software.Manifest, :get} => %{
        path: "/v1/software/manifest",
        responses: [200],
        public?: true
      }
    }
  end

  defp default_schemas,
    do: Core.Webserver.Spec.default_schemas()

  defp default_responses,
    do: Core.Webserver.Spec.default_responses()
end
