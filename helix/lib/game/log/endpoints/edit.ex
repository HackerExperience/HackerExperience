defmodule Game.Endpoint.Log.Edit do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Process.Log.Edit, as: LogEditProcess
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Log, Tunnel}

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "log_id"],
        "nip" => binary(),
        "log_id" => binary(),
        "tunnel_id" => binary(),
        "log_type" => binary(),
        "log_direction" => binary(),
        # NOTE: `log_data` is a map, but we are receiving it as string so we can parse it manually.
        # This is an acceptable trade-off for the time being, but in the future we want to improve
        # the SDK so it can handle this kind of input in a more rigid way.
        "log_data" => binary()
      }),
      ["nip", "log_id", "log_type", "log_direction", "log_data"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, log_id} <- cast_id(:log_id, parsed[:log_id], Log),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true),
         {:ok, log_params} <- cast_and_validate_log_params(parsed) do
      params =
        %{
          nip: nip,
          log_id: log_id,
          tunnel_id: tunnel_id,
          log_params: log_params
        }

      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  defp cast_and_validate_log_params(%{
         log_type: raw_type,
         log_direction: raw_direction,
         log_data: raw_data
       }) do
    raw_data = JSON.decode!(raw_data)
    params = Log.Validator.cast_params(raw_type, raw_direction, raw_data)

    if Log.Validator.validate_params(params) do
      {:ok, params}
    else
      {:error, {:log_params, :invalid}}
    end
  end

  def get_context(request, params, session) do
    %{nip: nip, log_id: log_id, tunnel_id: tunnel_id} = params

    with {true, %{entity: entity, target: target_server, tunnel: tunnel}} <-
           Henforcers.Server.has_access?(session.data.entity_id, nip, tunnel_id),
         {true, %{log: log}} <- Henforcers.Log.can_edit?(target_server, entity, log_id) do
      context = %{log: log, server: target_server, entity: entity, tunnel: tunnel}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, params, ctx, _session) do
    meta = %{log: ctx.log, tunnel: ctx.tunnel}

    case Svc.TOP.execute(LogEditProcess, ctx.server.id, ctx.entity.id, params.log_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error creating log edit process: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    process_eid = ID.to_external(process.id, session.data.entity_id, process.server_id)
    {:ok, %{request | response: {200, %{process_id: process_eid}}}}
  end

  defp format_henforcer_error({:server, :not_belongs}), do: "nip_not_found"
  defp format_henforcer_error({:tunnel, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:nip, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:log, :not_found}), do: "log_not_found"
  defp format_henforcer_error({:log, :deleted}), do: "log_deleted"
  defp format_henforcer_error({:log_visibility, :not_found}), do: "log_not_found"
end
