defmodule Game.Process.Server.Login do
  use Game.Process.Definition

  require Logger

  defstruct [:source_nip, :target_nip, :tunnel_id, :vpn_id]

  def new(
        %{source_nip: source_nip, target_nip: target_nip, tunnel_id: tunnel_id, vpn_id: vpn_id},
        _
      ) do
    %__MODULE__{
      source_nip: source_nip,
      target_nip: target_nip,
      tunnel_id: tunnel_id,
      vpn_id: vpn_id
    }
  end

  def get_process_type(_, _), do: :server_login

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent
    alias Game.Events.Network.TunnelCreateFailed, as: TunnelCreateFailedEvent

    @spec on_complete(Process.t(:server_login)) ::
            {:ok, TunnelCreatedEvent.event()}
            | {:error, TunnelCreateFailedEvent.event()}
    def on_complete(
          %{
            server_id: gateway_id,
            entity_id: entity_id,
            data: %{source_nip: s_nip, target_nip: t_nip, tunnel_id: tunnel_id, vpn_id: vpn_id}
          } = process
        ) do
      # Unlike most other Processable.on_complete/1, this one we start with a Universe (read)
      # connection. The main reason is this is a request that is only properly henforced once, here
      # at the process completion time. In order to avoid unnecessary global locks, we only upgrade
      # the connection to :write mode once we've validated the request is legit.
      Core.begin_context(:universe, :read)

      password = "todo"

      with {true, %{endpoint: endpoint, route_map: route_map}} <-
             Henforcers.Server.can_login?(entity_id, s_nip, t_nip, password, {tunnel_id, vpn_id}),
           parsed_links = build_parsed_links_from_route_map(route_map),
           # Now that we've validated the request, upgrade the connection to :write mode
           :ok <- Core.upgrade_to_write(),
           {:ok, tunnel} = Svc.Tunnel.create(parsed_links) do
        Core.commit()
        {:ok, TunnelCreatedEvent.new(tunnel, entity_id, gateway_id, endpoint.id)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to create tunnel: #{reason}")
          {:error, TunnelCreateFailedEvent.new(reason, process)}

        error ->
          Core.rollback()
          Logger.error("Unable to create tunnel: #{inspect(error)}")
          {:error, TunnelCreateFailedEvent.new(:internal, process)}
      end
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
    defp format_henforcer_error({:route, {:unreachable, _reason}}), do: "route_unreachable"
    defp format_henforcer_error({:route, reason}), do: "route_#{reason}"
    defp format_henforcer_error({:tunnel, :not_open}), do: "tunnel_not_open"
    defp format_henforcer_error({:tunnel, _}), do: "tunnel_not_found"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition

    @doc """
    The File we are transferring was deleted; kill this process.
    """
    def on_sig_src_file_deleted(_, _), do: :delete
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def time(_, _, _), do: 5

    def dynamic(_, _, _), do: []

    def static(_, _, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
  end

  defmodule Viewable do
    use Game.Process.Viewable.Definition

    def spec do
      selection(
        schema(%{}),
        []
      )
    end

    def render_data(_, _, _) do
      # TODO
      %{}
    end
  end
end
