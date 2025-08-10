defmodule Game.Services.Installation do
  alias Feeb.DB
  alias Game.{Installation, Server}

  @doc """
  Fetches an Installation matching the given filters.
  """
  @spec fetch(Server.id(), list, list) ::
          Installation.t() | nil
  def fetch(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:installations, :fetch}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns a list of File matching the given filters.
  """
  @spec list(Server.id(), list, list) ::
          [Installation.t()]
  def list(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_file_type_and_version: &query_by_file_type_and_version/1,
      all: &query_all/1
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  defp query_by_file_type_and_version({type, version}) when is_atom(type) and is_integer(version),
    do: DB.all({:installations, :by_file_type_and_version}, [type, version])

  defp query_all(true),
    do: DB.all(Installation)

  def uninstall(%Installation{} = installation) do
    DB.delete(installation)
  end
end
