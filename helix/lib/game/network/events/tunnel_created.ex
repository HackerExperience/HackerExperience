defmodule Game.Events.Network.TunnelCreated do
  use Core.Event.Definition
  alias Core.{ID, NIP}
  alias Game.{Index, Entity, Server, Tunnel}
  alias Game.Services, as: Svc

  defstruct [:tunnel, :entity_id, :gateway_id, :endpoint_id]

  @type t :: %__MODULE__{
          tunnel: Tunnel.t(),
          entity_id: Entity.id(),
          gateway_id: Server.id(),
          endpoint_id: Server.id()
        }

  @name :tunnel_created

  def new(
        %Tunnel{} = tunnel,
        %Entity.ID{} = entity_id,
        %Server.ID{} = gateway_id,
        %Server.ID{} = endpoint_id
      ) do
    %__MODULE__{
      tunnel: tunnel,
      entity_id: entity_id,
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
          tunnel_id: external_id(),
          source_nip: binary(),
          target_nip: binary(),
          access: enum(Tunnel.access_types()),
          index: Index.Server.endpoint_spec()
        }),
        [:tunnel_id, :source_nip, :target_nip, :access, :index]
      )
    end

    def generate_payload(%{data: %{gateway_id: gateway_id, tunnel: tunnel, entity_id: entity_id}}) do
      endpoint_id = Svc.NetworkConnection.fetch!(by_nip: tunnel.target_nip).server_id

      index =
        entity_id
        |> Index.Server.endpoint_index(endpoint_id, tunnel.target_nip)
        |> Index.Server.render_endpoint_index(entity_id)

      payload =
        %{
          tunnel_id: tunnel.id |> ID.to_external(entity_id, gateway_id),
          source_nip: NIP.to_external(tunnel.source_nip),
          target_nip: NIP.to_external(tunnel.target_nip),
          access: "#{tunnel.access}",
          index: index
        }

      {:ok, payload}
    end

    def whom_to_publish(%{data: %{entity_id: entity_id}}),
      do: %{player: entity_id}
  end

  defmodule Loggable do
    use Core.Event.Loggable.Definition

    def log_map(event) do
      %{
        entity_id: event.data.entity_id,
        target_id: event.data.endpoint_id,
        tunnel_id: event.data.tunnel.id,
        type: :server_login,
        data: %{
          gateway: %{nip: "$access_point"},
          endpoint: %{nip: "$exit_node"}
        }
      }
    end
  end
end
