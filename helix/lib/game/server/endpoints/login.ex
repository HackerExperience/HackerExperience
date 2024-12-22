defmodule Game.Endpoint.Server.Login do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent
  alias Game.Tunnel

  def input_spec do
    selection(
      schema(%{
        :__openapi_path_parameters => ["nip", "target_nip"],
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

  def get_params(request, parsed, _session) do
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
      {:error, {field, _reason}} ->
        {:error, %{request | response: {400, "invalid_input:#{field}"}}}
    end
  end

  def get_context(request, %{source_nip: source_nip, target_nip: target_nip} = params, session) do
    with {:ok, bounce_hops} <- resolve_bounce_hops(params[:tunnel_id], params[:vpn_id], source_nip),
         {true, %{route_map: %{gateway: gateway, endpoint: endpoint} = route_map}} <-
           Henforcers.Network.can_resolve_route?(source_nip, target_nip, bounce_hops),

         # Surely the user is not trying to connect (remotely) to their own server...
         # TODO: Not sure about this henforcement. It _should_ happen, but not here and applied to
         # any connection within the entire tunnel (what if VPN has a Gateway in it?).
         true <- gateway.entity_id != endpoint.entity_id || {:error, :self_connection},

         # Gateway always belongs to the user making the action (the one in the `session`)
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
      {:error, reason} ->
        {:error, %{request | response: {400, reason}}}

      {false, henforcer_error, _} ->
        error_msg = format_henforcer_error(henforcer_error)
        {:error, %{request | response: {400, error_msg}}}
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

  defp resolve_bounce_hops(nil, _vpn_id, _source_nip) do
    raise "TODO"
  end

  defp resolve_bounce_hops(_, _, _), do: {:error, :cant_use_vpn_and_tunnel_at_same_time}

  def handle_request(request, _params, context, session) do
    with {:ok, tunnel} <- Svc.Tunnel.create(context.parsed_links) do
      event =
        TunnelCreatedEvent.new(
          tunnel,
          session.data.player_id,
          context.gateway.id,
          context.endpoint.id
        )

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

  # We could provide a better error message (e.g. saying which NIP is unreachable), but I'll wait
  # for the UI to catch up before eagerly supporting this.
  defp format_henforcer_error({:route, {:unreachable, _unreachable_reason}}),
    do: "route_unreachable"

  defp format_henforcer_error({:route, :cyclical}),
    do: "route_cyclical"

  defp format_henforcer_error({:tunnel, reason}),
    do: "tunnel_#{reason}"
end
