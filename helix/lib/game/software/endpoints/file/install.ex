defmodule Game.Endpoint.File.Install do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{File}

  alias Game.Process.File.Install, as: FileInstallProcess

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "file_id"],
        "nip" => binary(),
        "file_id" => binary()
      }),
      ["nip", "file_id"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, file_id} <- cast_id(:file_id, parsed[:file_id], File) do
      params = %{nip: nip, file_id: file_id}
      {:ok, %{request | params: params}}
    end
  end

  def get_context(request, params, session) do
    with {true, %{server: server}} <- Henforcers.Network.nip_exists?(params.nip),
         {true, _} <- Henforcers.Server.server_belongs_to_entity?(server, session.data.entity_id),
         {true, %{file: file}} <- Henforcers.File.file_exists?(params.file_id, server),
         # TODO: Check entity has visibility to File
         true <- true do
      context =
        %{
          file: file,
          server: server,
          entity_id: session.data.entity_id
        }

      {:ok, %{request | context: context}}
    end
  end

  def handle_request(request, _params, ctx, _session) do
    process_params = %{}

    meta =
      %{
        file: ctx.file
      }

    case Svc.TOP.execute(FileInstallProcess, ctx.server.id, ctx.entity_id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error installing file: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, _) do
    {:ok, %{request | response: {200, %{process_id: process.id |> ID.to_external()}}}}
  end
end
