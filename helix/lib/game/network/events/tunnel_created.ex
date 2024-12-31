defmodule Game.Events.Network.TunnelCreated do
  use Core.Event.Definition
  alias Core.{ID, NIP}
  alias Game.{Index, Player, Server, Tunnel}
  alias Game.Services, as: Svc

  defstruct [:tunnel, :player_id, :gateway_id, :endpoint_id]

  @name :tunnel_created

  def new(
        %Tunnel{} = tunnel,
        %Player.ID{} = player_id,
        %Server.ID{} = gateway_id,
        %Server.ID{} = endpoint_id
      ) do
    %__MODULE__{
      tunnel: tunnel,
      player_id: player_id,
      gateway_id: gateway_id,
      endpoint_id: endpoint_id
    }
    |> Event.new()
  end

  defmodule Publishable do
    use Core.Event.Publishable.Definition

    def spec do
      selection(
        schema(%{
          tunnel_id: integer(),
          source_nip: binary(),
          target_nip: binary(),
          # TODO: Is Enum supported? oneOf?
          access: binary(),
          index: Index.Server.endpoint_spec()
        }),
        [:tunnel_id, :source_nip, :target_nip, :access, :index]
      )
    end

    def generate_payload(%{data: %{tunnel: tunnel, player_id: player_id}}) do
      endpoint_id = Svc.NetworkConnection.fetch!(by_nip: tunnel.target_nip).server_id

      index =
        player_id
        |> Index.Server.endpoint_index(endpoint_id, tunnel.target_nip)
        |> Index.Server.render_endpoint_index()

      payload =
        %{
          tunnel_id: tunnel.id |> ID.to_external(),
          source_nip: NIP.to_external(tunnel.source_nip),
          target_nip: NIP.to_external(tunnel.target_nip),
          access: "#{tunnel.access}",
          index: index
        }

      {:ok, payload}
    end

    def whom_to_publish(%{data: %{player_id: player_id}}),
      do: %{player: player_id}
  end

  defmodule Loggable do
    use Core.Event.Loggable.Definition

    def log_map(event) do
      %{
        entity_id: event.data.player_id,
        gateway_id: event.data.gateway_id,
        endpoint_id: event.data.endpoint_id,
        tunnel_id: event.data.tunnel.id,
        type_gateway: :remote_login_gateway,
        data_gateway: %{nip: "$access_point"},
        type_endpoint: :remote_login_endpoint,
        data_endpoint: %{nip: "$exit_node"}
      }
    end
  end
end
