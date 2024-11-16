defmodule Game.Endpoint.Server.Login do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Core.NIP
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent
  alias Game.Tunnel

  def input_spec do
    selection(
      schema(%{
        "nip" => binary(),
        "target_nip" => binary(),
        "tunnel_id" => integer()
      }),
      ["nip", "target_nip"]
    )
  end

  def output_spec(200) do
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, session) do
    # TODO: Validate NIPs, IDs...

    with {:ok, source_nip} <- cast_nip(:nip, parsed.nip),
         {:ok, target_nip} <- cast_nip(:target_nip, parsed.target_nip),
         {:ok, tunnel_id} <- cast_id(:tunnel_id, parsed[:tunnel_id], Tunnel, optional: true) do
      params =
        %{
          source_nip: source_nip,
          target_nip: target_nip,
          tunnel_id: tunnel_id
        }

      {:ok, %{request | params: params}}
    else
      e ->
        IO.puts("Fuuuu")
        raise e
    end
  end

  # TODO: One task worth doing to validate the assumptions (of Network and Tunnel in general) is to
  # pseudo-write the get_context (or more speicfically the Henforcer) of a remote request (like
  # FielDownload or LogFOrge), with the intention of making sure it's easy and doable to authenticate
  # the player's action.

  def get_context(request, %{source_nip: source_nip, target_nip: target_nip} = params, session) do
    with true <- true,
         # Both the source and target NIPs exist and correspond to valid servers
         {true, %{server: gateway}} <- Henforcers.Network.nip_exists?(source_nip),
         {true, %{server: endpoint}} <- Henforcers.Network.nip_exists?(target_nip),

         # Surely the user is not trying to connect (remotely) to their own server...
         # TODO: Not sure about this henforcement. It _should_ happen, but not here and applied to
         # any connection within the entire tunnel.
         true <- gateway.entity_id != endpoint.entity_id || {:error, :self_connection},
         # {:ok, bounce_hops} = Svc.Network.resolve_bounce_hops(params[:tunnel_id], params[:vpn_id]),

         {:ok, bounce_hops} = resolve_bounce_hops(params[:tunnel_id], params[:vpn_id], source_nip),

         # TODO: Now that I have a "RouteMap" being returned here, I can remove the two `nip_exists?`
         # calls above
         {true, %{route_map: route_map}} <-
           Henforcers.Network.can_resolve_route?(source_nip, target_nip, bounce_hops),

         # Gateway belongs to the user in this session
         # Note that, even for implicit bounces, it still makes sense for the request to begin from
         # the player's gateway (and then using `tunnel_id`). This removes confusion as to what
         # should be the actual gateway NIP (what if player has multiple connections to the remote?)
         true <- gateway.entity_id.id == session.data.player_id.id || {:error, :invalid_gateway},

         # TODO: Check {username, password} pair
         true <- true do
      context =
        %{
          gateway: gateway,
          endpoint: endpoint,
          parsed_links: build_parsed_links_from_route_map(route_map)
        }

      {:ok, %{request | context: context}}
    else
      e ->
        raise e
    end
  end

  # No tunnel or VPN ID -> it's a direct tunnel
  defp resolve_bounce_hops(nil, nil, _), do: {:ok, []}

  # Using a Tunnel to create an implicit bounce
  defp resolve_bounce_hops(%Tunnel.ID{} = tunnel_id, nil, source_nip) do
    with {true, %{tunnel: tunnel}} <- Henforcers.Network.tunnel_exists?(tunnel_id),
         true <- tunnel.source_nip == source_nip || {:error, {:tunnel, :not_authorized}},
         true <- tunnel.status == :open || {:error, {:tunnel, :not_open}} do
      {:ok, Svc.Network.resolve_bounce_hops(tunnel)}
    end
  end

  defp resolve_bounce_hops(nil, %{}) do
    raise "TODO"
  end

  defp resolve_bounce_hops(_, _), do: {:error, :cant_use_vpn_and_tunnel_at_same_time}

  def handle_request(request, _params, context, session) do
    with {:ok, tunnel} <- Svc.Tunnel.create(context.parsed_links) do
      event = TunnelCreatedEvent.new(tunnel, session.data.player_id)
      {:ok, %{request | events: [event]}}
    else
      e ->
        IO.inspect(e)
        raise "ERror!"
    end
  end

  def render_response(request, _data, _session) do
    {:ok, %{request | response: {200, %{}}}}
  end

  defp build_parsed_links_from_route_map(route_map) do
    gtw_link = [{route_map.gateway_nip, route_map.gateway.id}]
    endp_link = [{route_map.endpoint_nip, route_map.endpoint.id}]

    hops_links =
      Enum.map(route_map.hops, fn hop_nip ->
        [{hop_nip, route_map[hop_nip].server.id}]
      end)

    [gtw_link, hops_links, endp_link]
    |> List.flatten()
  end
end
