defmodule Game.Services.Connection do
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.{Connection, ConnectionGroup, Tunnel, TunnelLink}

  @doc """
  Creates a ConnectionGroup and the corresponding Connections for each link in the Tunnel.
  """
  def create(%Tunnel.ID{} = tunnel_id, links, connection_type) do
    with {:ok, group} <- create_group(tunnel_id, connection_type),
         {:ok, _connections} <- create_connections(group, links, connection_type) do
      {:ok, group}
    end
  end

  @doc """
  Creates a ConnectionGroup and the corresponding Connections for each link in the Tunnel.
  """
  def create(%Tunnel.ID{} = tunnel_id, connection_type),
    do: create(tunnel_id, Svc.Tunnel.list_links(on_tunnel: tunnel_id), connection_type)

  defp create_group(%Tunnel.ID{} = tunnel_id, connection_type) do
    %{
      tunnel_id: tunnel_id,
      type: connection_type
    }
    |> ConnectionGroup.new()
    |> DB.insert()
  end

  defp create_connections(%ConnectionGroup{} = group, [gtw_link, endp_link], type),
    do: create_peer_connections(group, gtw_link, endp_link, type)

  defp create_connections(%ConnectionGroup{} = group, links, type) do
    # We are in a Tunnel with intermediary hops. Only the (Exit Node, Endpoint) pair will have a
    # connection of type `type` created. All hops before that will have a `proxy` connection.
    # Note that, for `hop_links`, we include all links except the endpoint. The Exit Node is part
    # of that, since the proxy ends *at* the Exit Node.
    hop_links = Enum.slice(links, 0..-2//1)
    [exit_node_link, endp_link] = Enum.slice(links, -2, 2)

    with {:ok, direct_conns} <- create_peer_connections(group, exit_node_link, endp_link, type),
         {:ok, proxy_conns} <- create_proxy_connections(group, hop_links) do
      {:ok, proxy_conns ++ direct_conns}
    end
  end

  defp create_peer_connections(group, %TunnelLink{nip: src_nip}, %TunnelLink{nip: endp_nip}, type) do
    with {:ok, src_conn} <- create_individual_connection(group, src_nip, nil, endp_nip, type),
         {:ok, endp_conn} <- create_individual_connection(group, endp_nip, src_nip, nil, type) do
      {:ok, [src_conn, endp_conn]}
    end
  end

  defp create_proxy_connections(group, links) do
    # In a single pass, create a {nip, from_nip, to_nip} mapping of the proxy connections
    links
    |> Enum.reduce({[], nil}, fn
      %TunnelLink{} = link, {acc, nil} ->
        {acc, {link.nip, nil, nil}}

      %TunnelLink{} = link, {acc, {prev_nip, prev_from_nip, _}} ->
        prev_link = {prev_nip, prev_from_nip, link.nip}
        {[prev_link | acc], {link.nip, prev_nip, nil}}
    end)
    |> then(fn {acc, last_link} -> [last_link | acc] end)
    |> Enum.reverse()
    # Then, create an individual proxy connection for each entry
    |> Enum.reduce_while({:ok, []}, fn {nip, from_nip, to_nip}, {:ok, acc} ->
      case create_individual_connection(group, nip, from_nip, to_nip, :proxy) do
        {:ok, conn} ->
          {:cont, {:ok, [conn | acc]}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp create_individual_connection(%ConnectionGroup{} = group, nip, from_nip, to_nip, type) do
    %{
      nip: nip,
      from_nip: from_nip,
      to_nip: to_nip,
      type: type,
      group_id: group.id,
      tunnel_id: group.tunnel_id
    }
    |> Connection.new()
    |> DB.insert()
  end
end
