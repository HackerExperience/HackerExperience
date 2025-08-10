defmodule Game.Services.File do
  alias Feeb.DB
  alias Game.{Entity, File, FileVisibility, Installation, Server}

  def fetch(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:files, :fetch}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  def fetch!(%Server.ID{} = server_id, filter_params, opts \\ []) do
    server_id
    |> fetch(filter_params, opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  def fetch_visibility(%Entity.ID{} = entity_id, filter_params, opts \\ []) do
    filters = [
      by_file: &query_visibility_by_file/1
    ]

    Core.with_context(:player, entity_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns a list of File matching the given filters.
  """
  @spec list(Server.id(), list, list) ::
          [File.t()]
  def list(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_type_and_version: &query_file_by_type_and_version/1
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns a list of FileVisibility matching the given filters.
  """
  @spec list_visibility(Entity.id(), list, list) ::
          [FileVisibility.t()]
  def list_visibility(%Entity.ID{} = entity_id, filter_params, opts \\ []) do
    filters = [
      visible_on_server: {:all, {:file_visibilities, :by_server}, format: :raw}
    ]

    Core.with_context(:player, entity_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  def create_file(entity_id, server_id, file_params) do
    Core.with_context(:server, server_id, :write, fn ->
      with {:ok, file} <- insert_file(file_params),
           {:ok, _file_visibility} <- insert_file_visibility(entity_id, server_id, file.id) do
        {:ok, file}
      else
        {:error, reason, step} ->
          # TODO
          raise "Error creating file: #{inspect(reason)} - #{inspect(step)}"
      end
    end)
  end

  # TODO: This should be moved to the Installation service
  def install_file(%File{} = file) do
    %{
      file_type: file.type,
      file_version: file.version,
      file_id: file.id,
      memory_usage: get_memory_usage(file)
    }
    |> Installation.new()
    |> DB.insert()
  end

  def transfer(%File{} = file, {:download, gateway, endpoint}) do
    true = file.server_id == endpoint.id
    copy(file, gateway)
  end

  def transfer(%File{} = file, {:upload, gateway, endpoint}) do
    true = file.server_id == gateway.id
    copy(file, endpoint)
  end

  defp copy(%File{} = file, %Server{id: target_id}) do
    Core.assert_context_server_id!(target_id)

    %{
      type: file.type,
      name: file.name,
      version: file.version,
      size: file.size,
      path: "/"
    }
    |> File.new()
    |> DB.insert()
  end

  def delete(%File{} = file) do
    DB.delete(file)
  end

  defp insert_file(file_params) do
    %{
      name: file_params.name,
      type: file_params.type,
      version: file_params.version,
      size: file_params.size,
      path: file_params[:path] || "/"
    }
    |> File.new()
    |> DB.insert()
    |> on_error_add_step(:file)
  end

  defp insert_file_visibility(entity_id, server_id, file_id) do
    Core.with_context(:player, entity_id, :write, fn ->
      %{server_id: server_id, file_id: file_id}
      |> FileVisibility.new()
      |> DB.insert()
      |> on_error_add_step(:file_visibility)
    end)
  end

  # TODO
  defp get_memory_usage(%File{} = _file), do: 5

  defp query_file_by_type_and_version({type, version}) when is_atom(type) and is_integer(version),
    do: DB.all({:files, :by_type_and_version}, [type, version])

  defp query_visibility_by_file(%File{} = file),
    do: DB.one({:file_visibilities, :fetch}, [file.server_id, file.id])

  # TODO: Duplicated on Svc.Log; move to a util
  defp on_error_add_step({:ok, _} = r, _), do: r
  defp on_error_add_step({:error, reason}, step), do: {:error, reason, step}
end
