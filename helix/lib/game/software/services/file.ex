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

  # TODO
  defp get_memory_usage(%File{} = _file), do: 5

  defp query_visibility_by_file(%File{} = file),
    do: DB.one({:file_visibilities, :fetch}, [file.server_id, file.id])
end
