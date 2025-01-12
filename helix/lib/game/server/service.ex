defmodule Game.Services.Server do
  alias Feeb.DB
  alias Core.NIP
  alias Game.Services, as: Svc
  alias Game.{Entity, Process, Server, ServerMeta}

  def setup(%Entity{id: entity_id}) do
    with {:ok, %{id: server_id} = server} <- insert_server(entity_id) do
      DB.with_context(fn ->
        server_db_path = DB.Repo.get_path(Core.get_server_context(), server_id)
        false = File.exists?(server_db_path)

        # Create the shard, migrate and seed it with initial data
        Core.begin_context(:server, server_id, :write)
        seed_server!(server_id, entity_id)
        DB.commit()
      end)

      # Seed the Universe with required data for this Server to operate
      seed_universe!(server_id)

      {:ok, server}
    end
  end

  defp seed_server!(%Server.ID{} = server_id, %Entity.ID{} = entity_id) do
    # TODO: I'm not yet sure where, but this config should be defined elsewhere
    initial_resources =
      %{
        cpu: 1000,
        ram: 128
      }
      |> Process.Resources.from_map()

    %{id: server_id, entity_id: entity_id, resources: initial_resources}
    |> ServerMeta.new()
    |> DB.insert!()
  end

  defp seed_universe!(server_id) do
    # Make sure this server has a public connection to the Internet
    {:ok, _} =
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

  def get_meta(server_id) do
    Core.with_context(:server, server_id, :read, fn ->
      [meta] = DB.all(ServerMeta)
      meta
    end)
  end

  defp insert_server(entity_id) do
    %{entity_id: entity_id}
    |> Server.new()
    |> DB.insert()
  end
end
