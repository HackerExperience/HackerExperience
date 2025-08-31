defmodule Test.Utils.Network do
  use Test.Setup.Definition

  alias Game.{Connection, ConnectionGroup, Tunnel, TunnelLink}

  def get_all_tunnels do
    Core.with_context(:universe, :read, fn ->
      DB.all(Tunnel)
    end)
  end

  def get_all_tunnel_links do
    Core.with_context(:universe, :read, fn ->
      DB.all(TunnelLink)
    end)
    |> Enum.sort_by(& &1.idx)
  end

  def get_all_tunnel_links(%Tunnel{id: tunnel_id}),
    do: get_all_tunnel_links(tunnel_id)

  def get_all_tunnel_links(%Tunnel.ID{} = tunnel_id) do
    get_all_tunnel_links()
    |> Enum.filter(&(&1.tunnel_id == tunnel_id))
  end

  def get_all_connections do
    Core.with_context(:universe, :read, fn ->
      DB.all(Connection)
    end)
    |> Enum.sort_by(& &1.id)
  end

  def get_all_connections(%Tunnel{id: tunnel_id}),
    do: get_all_connections(tunnel_id)

  def get_all_connections(%Tunnel.ID{} = tunnel_id) do
    get_all_connections()
    |> Enum.filter(&(&1.tunnel_id == tunnel_id))
  end

  def get_all_connections(%ConnectionGroup{id: connection_group_id}),
    do: get_all_connections(connection_group_id)

  def get_all_connections(%ConnectionGroup.ID{} = connection_group_id) do
    get_all_connections()
    |> Enum.filter(&(&1.group_id == connection_group_id))
  end

  def get_all_connections(tunnel_or_group, type) when is_atom(type) do
    get_all_connections(tunnel_or_group)
    |> Enum.filter(&(&1.type == type))
  end

  def get_all_connection_groups do
    Core.with_context(:universe, :read, fn ->
      DB.all(ConnectionGroup)
    end)
    |> Enum.sort_by(& &1.id)
  end

  def get_all_connection_groups(%Tunnel{id: tunnel_id}),
    do: get_all_connection_groups(tunnel_id)

  def get_all_connection_groups(%Tunnel.ID{} = tunnel_id) do
    get_all_connection_groups()
    |> Enum.filter(&(&1.tunnel_id == tunnel_id))
  end
end
