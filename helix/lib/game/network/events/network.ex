defmodule Game.Events.Network do
  defmodule TunnelCreated do
    @moduledoc """
    The TunnelCreatedEvent is emitted after a (remote) Server login, which happens when a
    ServerLoginProcess reaches completion.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Core.{ID, NIP}
    alias Game.{Index, Entity, Server, Tunnel}

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

    def handlers(_, _) do
      [Handlers.Scanner]
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            tunnel_id: external_id(),
            source_nip: nip(),
            target_nip: nip(),
            access: enum(Tunnel.access_types()),
            index: Index.Server.endpoint_spec()
          }),
          [:tunnel_id, :source_nip, :target_nip, :access, :index]
        )
      end

      def generate_payload(%{
            data: %{
              gateway_id: gateway_id,
              endpoint_id: endpoint_id,
              tunnel: tunnel,
              entity_id: entity_id
            }
          }) do
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

  defmodule TunnelCreateFailed do
    @moduledoc """
    The TunnelCreateFailedEvent is emitted when the attempt to login to a remote server has failed.
    This may happen if the prerequisites verified at the ServerLoginProcess (upon completion) are
    not met.

    Note this error event is slightly more important than other error events, since we don't verify
    preconditions at the moment a ServerLoginProcess is created. In other words, this event is more
    likely to be emitted when compared to other error events.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            # TODO: Narrow down possible reasons
            reason: term,
            process: Process.t(:server_login)
          }

    @name :tunnel_create_failed

    def new(reason, %Process{} = process) do
      %__MODULE__{reason: reason, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            reason: binary(),
            process_id: external_id()
          }),
          [:reason, :process_id]
        )
      end

      def generate_payload(%{data: %{reason: reason, process: process}}) do
        entity_id = process.entity_id
        server_id = process.server_id

        payload =
          %{
            reason: reason,
            process_id: process.id |> ID.to_external(entity_id, server_id)
          }

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives this event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end
  end
end
