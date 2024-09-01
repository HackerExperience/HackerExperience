defmodule Game.Services.Server do
  alias Feeb.DB
  alias Game.ServerMapping
  alias Game.Entity

  def setup(%Entity{id: entity_id}) do
    with {:ok, %{server_id: server_id} = mapping} <- insert_mapping(entity_id) do
      DB.with_context(fn ->
        server_db_path = DB.Repo.get_path(:server, server_id)
        false = File.exists?(server_db_path)

        DB.begin(:server, server_id, :write)
        # TODO: Insert seed server data here, including S_meta
        DB.commit()
      end)

      {:ok, mapping}
    end
  end

  # Queries

  @doc """
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_server_id: {:one, {:server_mappings, :fetch}},
      list_by_entity_id: {:all, {:server_mappings, :list_by_entity_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  defp insert_mapping(entity_id) do
    %{entity_id: entity_id}
    |> ServerMapping.new()
    |> DB.insert()
  end
end
