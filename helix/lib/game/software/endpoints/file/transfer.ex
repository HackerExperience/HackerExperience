defmodule Game.Endpoint.File.Transfer do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{File, Tunnel}

  alias Game.Process.File.Transfer, as: FileTransferProcess

  @transfer_types [:download, :upload]
  @transfer_types_str Enum.map(@transfer_types, &to_string/1)

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "file_id"],
        "nip" => binary(),
        "file_id" => binary(),
        "transfer_type" => binary(),
        "tunnel_id" => integer()
      }),
      ["nip", "file_id", "transfer_type", "tunnel_id"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, xfer_type} <- cast_enum(:transfer_type, parsed[:transfer_type], @transfer_types_str),
         transfer_type = String.to_existing_atom(xfer_type),
         {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, file_id} <- cast_id(:file_id, parsed[:file_id], File),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel) do
      params = %{nip: nip, file_id: file_id, tunnel_id: tunnel_id, transfer_type: transfer_type}
      {:ok, %{request | params: params}}
    end
  end

  def get_context(request, params, session) do
    entity_id = session.data.entity_id
    %{nip: nip, file_id: file_id, tunnel_id: tunnel_id, transfer_type: transfer_type} = params

    with {true, %{entity: entity, gateway: gateway, endpoint: endpoint, tunnel: tunnel}} <-
           Henforcers.Server.has_access?(entity_id, nip, tunnel_id),
         transfer_info = {transfer_type, gateway, endpoint},
         {true, %{file: file}} <- Henforcers.File.can_transfer?(file_id, entity, transfer_info) do
      context = %{file: file, gateway: gateway, endpoint: endpoint, entity: entity, tunnel: tunnel}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, params, ctx, _session) do
    process_params = %{
      transfer_type: params.transfer_type,
      endpoint: ctx.endpoint
    }

    meta =
      %{
        file: ctx.file,
        tunnel: ctx.tunnel
      }

    case Svc.TOP.execute(FileTransferProcess, ctx.gateway.id, ctx.entity.id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error deleteing file: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, _) do
    {:ok, %{request | response: {200, %{process_id: process.id |> ID.to_external()}}}}
  end

  defp format_henforcer_error({:tunnel, :not_found}), do: "tunnel_not_found"
  defp format_henforcer_error({:nip, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
  defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
end
