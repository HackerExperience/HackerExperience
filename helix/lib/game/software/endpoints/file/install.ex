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
        "file_id" => external_id()
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
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, params, session) do
    entity_id = session.data.entity_id
    %{nip: nip, file_id: file_id} = params

    with {true, %{entity: entity, target: target_server}} <-
           Henforcers.Server.has_access?(entity_id, nip, nil),
         {true, %{file: file}} <- Henforcers.File.can_install?(target_server, entity, file_id) do
      context = %{file: file, server: target_server, entity: entity}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, _params, ctx, _session) do
    process_params = %{}

    meta =
      %{
        file: ctx.file
      }

    case Svc.TOP.execute(FileInstallProcess, ctx.server.id, ctx.entity.id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error installing file: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    process_eid = ID.to_external(process.id, session.data.entity_id, process.server_id)
    {:ok, %{request | response: {200, %{process_id: process_eid}}}}
  end

  defp format_henforcer_error({:nip, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
  defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
end
