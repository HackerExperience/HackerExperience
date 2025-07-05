defmodule Game.Endpoint.AppStore.Install do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Game.Process.Viewable, as: ProcessViewable
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Server, Software}

  alias Game.Process.AppStore.Install, as: AppStoreInstallProcess

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["server_id", "software_type"],
        "server_id" => external_id(),
        "software_type" => enum(Software.types(:installable) |> Enum.map(&to_string/1))
      }),
      ["server_id", "software_type"]
    )
  end

  def output_spec(200) do
    selection(
      schema(%{
        process: ProcessViewable.spec()
      }),
      [:process]
    )
  end

  def get_params(request, parsed, _session) do
    with {:ok, server_id} <- cast_id(:server_id, parsed[:server_id], Server),
         {:ok, software_type} <- {:ok, String.to_existing_atom(parsed.software_type)} do
      params = %{server_id: server_id, software_type: software_type}
      {:ok, %{request | params: params}}
    else
      {:error, {_, _} = error} ->
        {:error, %{request | response: {400, format_cast_error(error)}}}
    end
  end

  def get_context(request, params, session) do
    entity_id = session.data.entity_id
    %{server_id: server_id, software_type: software_type} = params

    with {true, %{entity: entity, target: server, access_type: :local}} <-
           Henforcers.Server.has_access?(entity_id, server_id, nil),
         {true, %{software: software}} <-
           Henforcers.AppStore.can_install?(server, software_type) do
      context = %{server: server, entity: entity, software: software}
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
        software: ctx.software
      }

    case Svc.TOP.execute(AppStoreInstallProcess, ctx.server.id, ctx.entity.id, process_params, meta) do
      {:ok, process} ->
        {:ok, %{request | result: %{process: process}}}

      {:error, reason} ->
        raise "Error starting AppStoreInstall process: #{inspect(reason)}"
    end
  end

  def render_response(request, %{process: process}, session) do
    render_process(request, process, session)
  end

  defp format_henforcer_error({_, :already_installed}), do: "file_already_installed"
  defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
  defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
  defp format_henforcer_error({:server, :not_belongs}), do: "server_not_found"
  defp format_henforcer_error({:server, :not_found}), do: "server_not_found"
end
