defmodule Game.Services.File do
  alias Feeb.DB
  alias Game.{File, FileVisibility, Installation, Server}

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

  # TODO
  defp get_memory_usage(%File{} = _file), do: 5
end
