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
        "tunnel_id" => integer()
      }),
      ["nip", "log_id"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, log_id} <- cast_id(:log_id, parsed[:log_id], Log),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true) do
      params =
        %{
          nip: nip,
          log_id: log_id,
          tunnel_id: tunnel_id,
          is_local?: is_nil(tunnel_id)
        }

      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, %{is_local?: true} = params, session) do
    with {true, %{server: server}} <- Henforcers.Network.nip_exists?(params.nip),
         {true, _} <- Henforcers.Server.belongs_to_entity?(server, session.data.entity_id),
         {true, %{log: log}} <- Henforcers.Log.log_exists?(params.log_id, nil, server),
         # TODO: Check entity has visibility (access) on this log
         true <- true do
      context =
        %{
          log: log,
          server: server,
          entity_id: session.data.entity_id,
          tunnel: nil
        }

      {:ok, %{request | context: context}}
    end
  end

  def handle_request(request, _params, ctx, _session) do
    # TODO
    process_params =
      %{
        type: :server_login,
        direction: :self,
        data: %{}
      }

    meta = %{log: ctx.log, tunnel: ctx.tunnel}

    case Svc.TOP.execute(LogEditProcess, ctx.server.id, ctx.entity_id, process_params, meta) do
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
end
