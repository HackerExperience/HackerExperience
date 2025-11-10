defmodule Game.Endpoint.Scanner.Edit do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Process.Scanner.Edit, as: ScannerEditProcess
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{ScannerInstance, Tunnel}

  alias Game.Scanner.Params.Connection, as: ConnParams
  alias Game.Scanner.Params.File, as: FileParams
  alias Game.Scanner.Params.Log, as: LogParams

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "instance_id"],
        "nip" => binary(),
        "instance_id" => binary(),
        "instance_type" => binary(),
        # NOTE: `log_data` is a map, but we are receiving it as string so we can parse it manually.
        # This is an acceptable trade-off for the time being, but in the future we want to improve
        # the SDK so it can handle this kind of input in a more rigid way.
        "target_params" => binary(),
        "tunnel_id" => maybe(binary())
      }),
      ["nip", "instance_id", "instance_type", "target_params", "tunnel_id"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, instance_id} <- cast_id(:instance_id, parsed[:instance_id], ScannerInstance),
         {:ok, instance_type} <- cast_instance_type(parsed.instance_type),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true),
         {:ok, target_params} <- cast_target_params(instance_type, parsed.target_params) do
      params =
        %{
          nip: nip,
          instance_id: instance_id,
          instance_type: instance_type,
          tunnel_id: tunnel_id,
          target_params: target_params
        }

      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  defp cast_instance_type("log"), do: {:ok, :log}
  defp cast_instance_type("connection"), do: {:ok, :connection}
  defp cast_instance_type("file"), do: {:ok, :file}
  defp cast_instance_type(_), do: {:error, {:instance_type, :invalid}}

  defp cast_target_params(instance_type, raw_target_params) do
    raw_target_params = JSON.decode!(raw_target_params)

    mod =
      case instance_type do
        :log -> LogParams
        :file -> FileParams
        :connection -> ConnParams
      end

    case mod.cast(raw_target_params) do
      {:ok, params} -> {:ok, params}
      :error -> {:error, {:target_params, :invalid}}
    end
  end

  def get_context(request, params, session) do
    with {true, %{entity: entity, target: target_server, tunnel: tunnel}} <-
           Henforcers.Server.has_access?(session.data.entity_id, params.nip, params.tunnel_id),
         {true, %{instance: instance}} <- Henforcers.Scanner.can_edit?(entity, params.instance_id),
         {true, _} <- Henforcers.Scanner.valid_params?(instance, params.target_params) do
      context = %{instance: instance, server: target_server, entity: entity, tunnel: tunnel}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, params, ctx, _session) do
    process_params = %{target_params: params.target_params}
    meta = %{instance: ctx.instance, tunnel: ctx.tunnel}

    case Svc.TOP.execute(ScannerEditProcess, ctx.server.id, ctx.entity.id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error creating ScannerEditProcess: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    process_eid = ID.to_external(process.id, session.data.entity_id, process.server_id)
    {:ok, %{request | response: {200, %{process_id: process_eid}}}}
  end

  defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
  defp format_henforcer_error({:instance, :not_found}), do: "instance_not_found"
  defp format_henforcer_error({:instance, :not_belongs}), do: "instance_not_found"
  defp format_henforcer_error({:tunnel, :not_found}), do: "tunnel_not_found"
  defp format_henforcer_error({:instance, :invalid_params}), do: "instance_invalid_params"
end
