defmodule Game.Services.File do
  alias Feeb.DB
  alias Game.{File, Installation}

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:files, :fetch}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  def fetch_visibility(entity_id, filter_params, opts \\ []) do
    filters = [
      by_file: &query_visibility_by_file/1
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

  def delete(%File{} = file) do
    DB.delete(file)
  end

  # TODO
  defp get_memory_usage(%File{} = _file), do: 5

  defp query_visibility_by_file(%File{} = file),
    do: DB.one({:file_visibilities, :fetch}, [file.server_id, file.id])
end
