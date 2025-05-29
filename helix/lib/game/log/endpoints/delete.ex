defmodule Game.Endpoint.Log.Delete do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Game.Process.Log.Delete, as: LogDeleteProcess
  alias Game.Process.Viewable, as: ProcessViewable
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Log, Tunnel}

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "log_id"],
        "nip" => binary(),
        "log_id" => binary(),
        "tunnel_id" => binary()
      }),
      ["nip", "log_id"]
    )
  end

  def output_spec(200) do
    selection(
      schema(%{
        process: ProcessViewable.spec(),
        log_id: binary()
      }),
      [:process, :log_id]
    )
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, log_id} <- cast_id(:log_id, parsed[:log_id], Log),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true) do
      params =
        %{
          nip: nip,
          log_id: log_id,
          log_eid: parsed[:log_id],
          tunnel_id: tunnel_id
        }

      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, params, session) do
    %{nip: nip, log_id: log_id, tunnel_id: tunnel_id} = params

    with {true, %{entity: entity, target: target_server, tunnel: tunnel}} <-
           Henforcers.Server.has_access?(session.data.entity_id, nip, tunnel_id),
         {true, %{log: log}} <- Henforcers.Log.can_delete?(target_server, entity, log_id) do
      context = %{log: log, server: target_server, entity: entity, tunnel: tunnel}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, %{log_eid: log_eid}, ctx, _session) do
    process_params = %{}
    meta = %{log: ctx.log, tunnel: ctx.tunnel}

    case Svc.TOP.execute(LogDeleteProcess, ctx.server.id, ctx.entity.id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{log_eid: log_eid, process: process}}}

      {:error, reason} ->
        raise "Error creating log delete process: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process, log_eid: log_eid}, session) do
    render_process(request, process, session, %{log_id: log_eid})
  end

  defp format_henforcer_error({:server, :not_belongs}), do: "nip_not_found"
  defp format_henforcer_error({:tunnel, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:nip, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:log, :not_found}), do: "log_not_found"
  defp format_henforcer_error({:log, :deleted}), do: "log_already_deleted"
  defp format_henforcer_error({:log_visibility, :not_found}), do: "log_not_found"
end
