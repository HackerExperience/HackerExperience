defmodule Test.Setup.Server do
  use Test.Setup.Definition
  alias Game.{Server}

  @doc """
  Creates a Server entry with real shards.
  """
  def new(opts \\ []) do
    opts
    |> get_source_entity()
    |> new_server(opts)
    |> with_custom_data(opts)
    |> gather_server_data(opts)
  end

  @doc """
  Creates a full Server entry, meaning it not only has the shards but also useful and relevant
  data that may be helpful for tests. For example, it has an Internet-connected NIP.
  """
  def new_full(opts \\ []) do
    opts
    |> new()
    |> with_custom_data(opts)
    |> create_server_data(opts)
    |> gather_server_data(opts)
  end

  @doc """
  Inserts the Server entry with the corresponding FKs (Entity, Player etc) without shards.
  """
  def new_lite(opts \\ []) do
    related =
      case get_source_entity(opts) do
        {:existing_entity, entity} ->
          %{entity: entity}

        {:new_entity, entity_type} ->
          S.entity_lite(type: entity_type)
      end

    server =
      [entity_id: related.entity.id]
      |> Keyword.merge(opts)
      |> params()
      |> Server.new()
      |> DB.insert!()

    %{server: server}
    |> Map.merge(related)
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:server)
  def new_full!(opts \\ []), do: opts |> new_full() |> Map.fetch!(:server)
  def new_lite!(opts \\ []), do: opts |> new_lite() |> Map.fetch!(:server)

  def params(opts \\ []) do
    %{entity_id: Kw.fetch!(opts, :entity_id)}
  end

  # Private

  defp get_source_entity(opts) do
    cond do
      opts[:entity] ->
        {:existing_entity, opts[:entity]}

      opts[:entity_id] ->
        {:existing_entity, Svc.Entity.fetch!(by_id: opts[:entity_id])}

      opts[:entity_type] ->
        true = opts[:entity_type] in [:player, :npc, :clan]
        {:new_entity, opts[:entity_type]}

      true ->
        {:new_entity, :player}
    end
  end

  # Needs to create entity alongside server
  defp new_server({:new_entity, entity_type}, _) do
    S.entity(type: entity_type)
  end

  # Entity already exists; we are adding a new server to it
  defp new_server({:existing_entity, entity}, _) do
    {:ok, server} = Svc.Server.setup(entity)
    %{server: server, entity: entity}
  end

  defp with_custom_data(%{server: server} = related, opts) do
    maybe_update_resources(server.id, opts)

    related
  end

  defp maybe_update_resources(%Server.ID{} = server_id, opts) do
    if custom_resources = opts[:resources] do
      U.Server.update_resources(server_id, custom_resources)
    end
  end

  # We were tasked with having a "complete" server. Let's make it complete, then
  defp create_server_data(%{server: _server, entity: _entity} = related, _opts) do
    # TODO: No longer creating a NIP because that's automatic, but here is where I'd create more
    # useful data for a "full" server
    related
  end

  defp gather_server_data(%{server: server} = related, _opts) do
    network_connection = Svc.NetworkConnection.fetch!(by_server_id: server.id)

    related
    |> Map.merge(%{nip: network_connection.nip})
    |> Map.merge(%{meta: Svc.Server.get_meta(server.id)})
  end
end
