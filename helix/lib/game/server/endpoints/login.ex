defmodule Game.Endpoint.Server.Login do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Tunnel}

  alias Game.Process.Server.Login, as: ServerLoginProcess

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "target_nip"],
        "nip" => binary(),
        "target_nip" => binary(),
        "tunnel_id" => external_id()
      }),
      ["nip", "target_nip"]
    )
  end

  def output_spec(200) do
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, source_nip} <- cast_nip(:nip, parsed.nip),
         {:ok, target_nip} <- cast_nip(:target_nip, parsed.target_nip),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true) do
      params =
        %{
          source_nip: source_nip,
          target_nip: target_nip,
          tunnel_id: tunnel_id,
          vpn_id: nil
        }

      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, params, session) do
    entity_id = session.data.entity_id

    with {true, %{server: gateway}} <- Henforcers.Network.nip_exists?(params.source_nip),
         {true, %{entity: entity}} <- Henforcers.Server.belongs_to_entity?(gateway, entity_id) do
      context =
        %{
          gateway: gateway,
          entity: entity,
          source_nip: params.source_nip,
          target_nip: params.target_nip,
          tunnel_id: params[:tunnel_id],
          vpn_id: params[:vpn_id]
        }

      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, _params, ctx, _session) do
    process_params = %{
      source_nip: ctx.source_nip,
      target_nip: ctx.target_nip,
      tunnel_id: ctx.tunnel_id,
      vpn_id: ctx.vpn_id
    }

    case Svc.TOP.execute(ServerLoginProcess, ctx.gateway.id, ctx.entity.id, process_params, %{}) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error creating ServerLoginProcess: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    process_eid = ID.to_external(process.id, session.data.entity_id, process.server_id)
    {:ok, %{request | response: {200, %{process_id: process_eid}}}}
  end

  defp format_henforcer_error({:nip, :not_found}), do: "invalid_gateway"
  defp format_henforcer_error({:server, :not_belongs}), do: "invalid_gateway"
end
