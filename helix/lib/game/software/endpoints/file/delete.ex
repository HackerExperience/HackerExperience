defmodule Game.Endpoint.File.Delete do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{File, Tunnel}

  alias Game.Process.File.Delete, as: FileDeleteProcess

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "file_id"],
        "nip" => binary(),
        "file_id" => binary(),
        "tunnel_id" => integer()
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
         {:ok, file_id} <- cast_id(:file_id, parsed[:file_id], File),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true) do
      params = %{nip: nip, file_id: file_id}
      {:ok, %{request | params: params}}
    end
  end

  def get_context(request, params, session) do
    with {true, %{server: server}} <- Henforcers.Network.nip_exists?(params.nip),
         {true, %{file: file, entity: entity}} <-
           Henforcers.File.can_delete?(server, session.data.entity_id, params.file_id) do
      context = %{file: file, server: server, entity: entity}
      {:ok, %{request | context: context}}
    else
      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
    end
  end

  def handle_request(request, _params, ctx, session) do
    entity_id = session.data.entity_id

    process_params = %{}

    meta =
      %{
        file: ctx.file
      }

    # TODO
    # case Svc.TOP.execute(FileDeleteProcess, ctx.server.id, ctx.entity.id, process_params, meta) do
    #   {:ok, process} ->
    #     {:ok, %{request | result: %{process: process}}}

    #   {:error, reason} ->
    #     raise "Error deleteing file: #{inspect(reason)}"
    # end

    {:ok, %{request | result: %{process: %{id: %Game.Process.ID{id: 1}}}}}
  end

  def render_response(request, %{process: process}, _) do
    {:ok, %{request | response: {200, %{process_id: process.id |> ID.to_external()}}}}
  end

  defp format_henforcer_error({:nip, :not_found}), do: "nip_not_found"
  defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
  defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
end
