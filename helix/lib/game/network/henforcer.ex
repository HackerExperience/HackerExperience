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

  @type all_nips_exist_relay ::
          %{
            (nip :: term()) => %{
              server: server :: term()
            }
          }

  @type all_nips_exist_error :: {false, {:nip, :not_found, nip :: term()}, %{}}

  @spec all_nips_exist?([nip :: term()]) ::
          {true, all_nips_exist_relay}
          | all_nips_exist_error
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

  @type tunnel_exists_relay :: %{tunnel: term()}
  @type tunnel_exists_error :: {false, {:tunnel, :not_found}, %{}}

  @spec tunnel_exists?(tunnel_id :: Tunnel.ID.t()) ::
          {true, tunnel_exists_relay}
          | tunnel_exists_error
  def tunnel_exists?(%Tunnel.ID{} = tunnel_id) do
    case Svc.Tunnel.fetch(by_id: tunnel_id) do
      %_{} = tunnel ->
        Henforcer.success(%{tunnel: tunnel})

      nil ->
        Henforcer.fail({:tunnel, :not_found})
    end
  end

  @type can_resolve_route_relay ::
          %{
            route_map: map(),
            player: term()
          }

  @type can_resolve_route_error ::
          is_route_reachable_error
          | can_access_route_hops_error

  @doc """
  Determines whether a given route (gateway, endpoint, [hops]) can be resolved.

  It performs several checks, including:
  - Is the route reachable?
  - Are all NIPs within the same network?
  - Are there cycles?
  - Does the user have HDB access for all intermediary hops?

  Do keep in mind this does not check if the user has HDB access to the endpoint, since the endpoint
  password is an *input* of the request hitting this henforcer.
  """
  @spec can_resolve_route?(nip :: term(), nip :: term(), [nip :: term()]) ::
          {true, can_resolve_route_relay}
          | can_resolve_route_error
  def can_resolve_route?(%NIP{} = gtw_nip, %NIP{} = endp_nip, bounce_hops) do
    full_route = [gtw_nip | bounce_hops] ++ [endp_nip]

    with {true, %{nips_servers: nips_servers}} <- is_route_reachable?(full_route),
         route_map = build_route_map(gtw_nip, endp_nip, bounce_hops, nips_servers),
         {true, r2} = can_access_route_hops?(route_map) do
      {true, Map.merge(r2, %{route_map: route_map})}
    end
  end

  @type can_access_route_hops_relay :: Henforcers.Entity.is_player_relay()
  @type can_access_route_hops_error :: Henforcers.Entity.is_player_error()

  @spec can_access_route_hops?(route_map :: map()) ::
          {true, can_access_route_hops_relay}
          | can_access_route_hops_error
  def can_access_route_hops?(%{gateway: %{entity_id: source_entity_id}} = _route_map) do
    with {true, %{player: _player_id} = r} <- Henforcers.Entity.is_player?(source_entity_id) do
      # Now we:
      # 1. Grab all relevant HDB entries (in a single query or doing N+1)
      # 2. Identify that the HDB password matches the hop's current password
      # TODO since neither HDB nor the concept of "Server password" are implemented
      {true, r}
    end
  end

  # TODO: Move this (and parsed link thingie) to TunnelService
  # This is an important data structure that may be used outside Henforcer. Move it to TunnelService
  defp build_route_map(gtw_nip, endp_nip, hops, nips_servers) do
    nips_servers
    |> Map.put(:hops, hops)
    |> Map.put(:gateway, Map.fetch!(nips_servers, gtw_nip).server)
    |> Map.put(:gateway_nip, gtw_nip)
    |> Map.put(:endpoint, Map.fetch!(nips_servers, endp_nip).server)
    |> Map.put(:endpoint_nip, endp_nip)
  end

  @type is_route_reachable_relay :: %{nips_servers: all_nips_exist_relay}
  @type is_route_reachable_error ::
          {false, {:route, {:unreachable, {:nip_not_found, nip :: term()}}}, %{}}
          | {false, {:route, {:unreachable, :multiple_networks}}, %{}}
          | {false, {:route, :cyclical}, %{}}

  @doc """
  Identifies whether a route is reachable.

  - All NIPs must exist
  - All NIPs must be within the same network*
  - There must be no cycles in the network

  *This will change once I implement support for cross-network tunnels
  """
  @spec is_route_reachable?([nip :: term()]) ::
          {true, is_route_reachable_relay}
          | is_route_reachable_error
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

    # TODO: detect cycles in routes
    route_has_no_cycles? = fn ->
      # This always returns true. Dialyzer hack.
      if Enum.random([1]) == 1, do: true, else: false
    end

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
        {false, {:route, :cyclical}, %{}}
    end
  end
end
