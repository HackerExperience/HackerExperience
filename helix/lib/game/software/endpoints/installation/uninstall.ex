defmodule Game.Endpoint.Installation.Uninstall do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Installation}

  alias Game.Process.Installation.Uninstall, as: InstallationUninstallProcess

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "installation_id"],
        "nip" => binary(),
        "installation_id" => binary()
      }),
      ["nip", "installation_id"]
    )
  end

  def output_spec(200) do
    # TODO
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, _session) do
    with {:ok, nip} <- cast_nip(:nip, parsed.nip),
         {:ok, inst_id} <- cast_id(:installation_id, parsed[:installation_id], Installation) do
      params = %{nip: nip, installation_id: inst_id}
      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, params, session) do
    entity_id = session.data.entity_id
    %{nip: nip, installation_id: installation_id} = params

    with {true, %{entity: entity, target: target_server}} <-
           Henforcers.Server.has_access?(entity_id, nip, nil),
         {true, %{installation: installation}} <-
           Henforcers.Installation.can_uninstall?(target_server, entity, installation_id) do
      context = %{installation: installation, server: target_server, entity: entity}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, _params, %{server: server, entity: entity} = ctx, _session) do
    params = %{}

    meta =
      %{
        installation: ctx.installation
      }

    case Svc.TOP.execute(InstallationUninstallProcess, server.id, entity.id, params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error uninstalling file: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    process_eid = ID.to_external(process.id, session.data.entity_id, process.server_id)
    {:ok, %{request | response: {200, %{process_id: process_eid}}}}
  end

  defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
  defp format_henforcer_error({:installation, :not_found}), do: "installation_not_found"
end
