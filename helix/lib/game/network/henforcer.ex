defmodule Game.Henforcers.Network do
  alias Core.{Henforcer, NIP}
  alias Game.Henforcers
  alias Game.Services, as: Svc
  alias Game.Tunnel

  @type nip_exists_relay :: Henforcers.Server.server_exists_relay()
  @type nip_exists_error :: {false, {:nip, :not_found}, %{}}

  @spec nip_exists?(nip :: term()) ::
          {true, nip_exists_relay}
          | nip_exists_error
  def nip_exists?(%NIP{} = nip) do
    case Svc.NetworkConnection.fetch(by_nip: nip) do
      %_{server_id: server_id} ->
        server_id
        |> Henforcers.Server.server_exists?()
        |> Henforcer.henforce_else({:nip, :not_found})

      nil ->
        Henforcer.fail({:nip, :not_found})
    end
  end

  def all_nips_exist?(nips) do
    Enum.reduce_while(nips, {true, %{}}, fn nip, {true, acc} ->
      case nip_exists?(nip) do
        {true, relay} ->
          {:cont, {true, Map.put(acc, nip, relay)}}

        {false, _, _} ->
          {:halt, {false, {:nip, :not_found, nip}, %{}}}
      end
    end)
  end

  def tunnel_exists?(%Tunnel.ID{} = tunnel_id) do
    case Svc.Tunnel.fetch(by_id: tunnel_id) do
      %_{} = tunnel ->
        Henforcer.success(%{tunnel: tunnel})

      nil ->
        Henforcer.fail({:tunnel, :not_found})
    end
  end

  # `hops` is a list of NIPs
  def can_resolve_route?(%NIP{} = gtw_nip, %NIP{} = endp_nip, bounce_hops) do
    # Q1: Is route reachable?
    # - A1.1 - All NIPs within same network (this changes once we implement multiple networks)
    # Q2: Are there cycles?
    # - A2.1 - No-op for now (assume no cycles)
    # Q3: Does user has HDB access (knows {username, password}) for all intermediary hops?
    # - A3.1 - Mock query so HDB always returns a real pair (i.e. assume players always have access)
    # - A3.2 - But basically, for each NIP (ex-source and ex-target), make sure player has HDB entry
    # - A3.3 - Then, make sure HDB entry is up-to-date with the current server password

    full_route = [gtw_nip | bounce_hops] ++ [endp_nip]

    with {true, %{nips_servers: nips_servers}} <- is_route_reachable?(full_route),
         route_map = build_route_map(gtw_nip, endp_nip, bounce_hops, nips_servers),
         {true, r2} = can_access_route_hops?(route_map) do
      {true, Map.merge(r2, %{route_map: route_map})}
    end
  end

  def can_access_route_hops?(%{gateway: %{entity_id: source_entity_id}} = route_map) do
    with {true, %{player: _player_id} = r} <- Henforcers.Entity.is_player?(source_entity_id) do
      # Now we:
      # 1. Grab all relevant HDB entries (in a single query or doing N+1)
      # 2. Identify that the HDB password matches the hop's current password
      # TODO since neither HDB nor the concept of "Server password" are implemented
      {true, r}
    end
  end

  defp build_route_map(gtw_nip, endp_nip, hops, nips_servers) do
    nips_servers
    |> Map.put(:hops, hops)
    |> Map.put(:gateway, Map.fetch!(nips_servers, gtw_nip).server)
    |> Map.put(:gateway_nip, gtw_nip)
    |> Map.put(:endpoint, Map.fetch!(nips_servers, endp_nip).server)
    |> Map.put(:endpoint_nip, endp_nip)
  end

  @doc """
  Identifies whether a route is reachable.

  - All NIPs must exist
  - All NIPs must be within the same network*
  - There must be no cycles in the network

  *This will change once I implement support for cross-network tunnels
  """
  def is_route_reachable?(nips) do
    all_nips_in_same_network? = fn ->
      total_networks =
        nips
        |> Enum.map(& &1.network_id)
        |> Enum.uniq()
        |> length()

      # Note this will change once we start supporting cross-network tunnels
      total_networks == 1
    end

    # TODO
    route_has_no_cycles? = fn -> true end

    with {true, nips_relay} <- all_nips_exist?(nips),
         true <- all_nips_in_same_network?.() || {false, :multiple_networks},
         true <- route_has_no_cycles?.() || {false, :cyclical} do
      {true, %{nips_servers: nips_relay}}
    else
      {false, {:nip, :not_found, nip}, _} ->
        {false, {:route, {:unreachable, {:nip_not_found, nip}}}, %{}}

      {false, :multiple_networks} ->
        {false, {:route, {:unreachable, :multiple_networks}}, %{}}

      {false, :cyclical} ->
        {false, {:route, :cyclical}}
    end
  end
end
