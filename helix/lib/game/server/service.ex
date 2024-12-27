defmodule Game.Services.Server do
  alias Feeb.DB
  alias Core.NIP
  alias Game.Services, as: Svc
  alias Game.{Entity, Server}

  def setup(%Entity{id: entity_id}) do
    with {:ok, %{id: server_id} = server} <- insert_server(entity_id) do
      DB.with_context(fn ->
        server_db_path = DB.Repo.get_path(Core.get_server_context(), server_id)
        false = File.exists?(server_db_path)

        # Create the shard, migrate and seed it with initial data
        Core.begin_context(:server, server_id, :write)
        seed_new_server!(:server, server_id)
        DB.commit()
      end)

      # Seed the new server with data (in the Universe shard)
      seed_new_server!(:universe, server_id)

      {:ok, server}
    end
  end

  defp seed_new_server!(:server, _server_id) do
    # TODO: Insert seed server data here, including S_meta
  end

  defp seed_new_server!(:universe, server_id) do
    # Make sure this server has a public connection to the Internet
    %{server_id: server_id, nip: NIP.new(0, Renatils.Random.ip())}
    |> Svc.NetworkConnection.create()
  end

  # Queries

  @doc """
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:servers, :fetch}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  def list(filter_params, opts \\ []) do
    filters = [
      by_entity_id: {:all, {:servers, :by_entity_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  defp insert_server(entity_id) do
    %{entity_id: entity_id}
    |> Server.new()
    |> DB.insert()
  end
end
