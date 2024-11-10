defmodule Test.Setup.Server do
  use Test.Setup.Definition
  alias Game.Server

  @doc """
  Creates a Server entry with real shards.
  """
  def new(opts \\ []) do
    opts
    |> get_source_entity()
    |> new_server(opts)
  end

  @doc """
  Creates a full Server entry, meaning it not only has the shards but also useful and relevant
  data that may be helpful for tests. For example, it has an Internet-connected NIP.
  """
  def new_full(opts \\ []) do
    opts
    |> new()
    |> create_server_data(opts)
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

  # We were tasked with having a "complete" server. Let's make it complete, then
  defp create_server_data(%{server: server, entity: _entity} = related, opts) do
    # Surely a complete server has a working NIP and is connected to the public Internet
    network_connection = S.network_connection!(server.id)

    related
    |> Map.merge(%{nip: network_connection.nip})
  end
end
