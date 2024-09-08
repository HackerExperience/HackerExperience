defmodule Game.Services.Server do
  alias Feeb.DB
  alias Game.{Entity, Server}

  def setup(%Entity{id: entity_id}) do
    with {:ok, %{id: server_id} = server} <- insert_server(entity_id) do
      DB.with_context(fn ->
        server_db_path = DB.Repo.get_path(Core.get_server_context(), server_id)
        false = File.exists?(server_db_path)

        Core.begin_context(:server, server_id, :write)
        # TODO: Insert seed server data here, including S_meta
        DB.commit()
      end)

      {:ok, server}
    end
  end

  # Queries

  @doc """
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:servers, :fetch}},
      list_by_entity_id: {:all, {:servers, :list_by_entity_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  defp insert_server(entity_id) do
    %{entity_id: entity_id}
    |> Server.new()
    |> DB.insert()
  end
end
