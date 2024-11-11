defmodule Game.Endpoint.Server.Login do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec

  alias Core.NIP
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent

  def input_spec do
    selection(
      schema(%{
        "nip" => binary(),
        "target_nip" => binary()
      }),
      ["nip", "target_nip"]
    )
  end

  def output_spec(200) do
    selection(schema(%{}), [])
  end

  def get_params(request, parsed, session) do
    # TODO: Validate NIPs
    params =
      %{
        source_nip: parsed.nip |> NIP.from_external(),
        target_nip: parsed.target_nip |> NIP.from_external()
      }

    {:ok, %{request | params: params}}
  end

  def get_context(request, params, session) do
    IO.inspect(session)
    IO.inspect(params)

    with true <- true,
         # Both the source and target NIPs exist and correspond to valid servers
         {true, %{server: gateway}} <- Henforcers.Network.nip_exists?(params.source_nip),
         {true, %{server: endpoint}} <- Henforcers.Network.nip_exists?(params.target_nip),

         # Surely the user is not trying to connect (remotely) to their own server...
         # TODO: Not sure about this henforcement. It _should_ happen, but not here and applied to
         # any connection within the entire tunnel.
         true <- gateway.entity_id != endpoint.entity_id || {:error, :self_connection},
         hops = Svc.Network.resolve_route(params[:tunnel_id], params[:vpn_id]),

         # TODO: Now that I have a "RouteMap" being returned here, I can remove the two `nip_exists?`
         # calls above
         {true, r} <- Henforcers.Network.can_use_route?(params.source_nip, params.target_nip, hops),

         # Gateway belongs to the user in this session
         # Note that, even for implicit bounces, it still makes sense for the request to being from
         # the player's gateway (and then using `tunnel_id`). This removes confusion as to what
         # should be the actual gateway NIP (what if player has multiple connections to the remote?)
         true <- gateway.entity_id.id == session.data.player_id.id || {:error, :invalid_gateway},

         # TODO: Check {username, password} pair
         # TODO: Check all links when `vpn_id` and/or `tunnel_id` are specified in `params`
         true <- true do
      context =
        %{
          gateway: gateway,
          endpoint: endpoint,
          # TODO: Find a better way to build parsed_links (when with `vpn_id` or implicit vpn)
          parsed_links: [{params.source_nip, gateway.id}, {params.target_nip, endpoint.id}]
        }

      {:ok, %{request | context: context}}
    else
      e ->
        raise e
    end
  end

  def handle_request(request, _params, context, session) do
    with {:ok, tunnel} <- Svc.Network.create_tunnel(context.parsed_links) do
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
end
