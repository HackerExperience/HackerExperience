defmodule Game.Handlers.Scanner do
  @behaviour Core.Event.Handler.Behaviour

  use Docp

  require Logger

  alias Game.Services, as: Svc
  alias Game.{Entity, Server, Tunnel}

  alias Game.Events.Network.TunnelClosed, as: TunnelClosedEvent
  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent
  alias Game.Events.Player.IndexRequested, as: IndexRequestedEvent
  alias Game.Events.Scanner.InstancesCreated, as: ScannerInstancesCreatedEvent

  @docp """
  Make sure ScannerInstances are set up every time a player logs in.
  """
  def on_event(%IndexRequestedEvent{player_id: player_id}, _) do
    gateways = Svc.Server.list(by_entity_id: player_id)
    entity_id = Entity.ID.new(player_id)

    events =
      Enum.reduce(gateways, [], fn %{id: server_id}, acc ->
        create_scanner_instances(entity_id, server_id, tunnel_id: nil) ++ acc
      end)

    {:ok, events}
  end

  @docp """
  Make sure ScannerInstances are set up every time a player logs into a remote server.
  """
  def on_event(
        %TunnelCreatedEvent{tunnel: tunnel, entity_id: entity_id, endpoint_id: endpoint_id},
        _
      ) do
    {:ok, create_scanner_instances(entity_id, endpoint_id, tunnel_id: tunnel.id)}
  end

  @docp """
  Every time a Tunnel is closed, we have to delete any Instances that are linked to it.
  """
  def on_event(%TunnelClosedEvent{tunnel: tunnel}, _) do
    Svc.Scanner.destroy_instances(by_tunnel: tunnel.id)
    {:ok, []}
  end

  @spec create_scanner_instances(Entity.id(), Server.id(), tunnel_id: Tunnel.id() | nil) ::
          [ScannerInstancesCreatedEvent.event()]
  defp create_scanner_instances(entity_id, server_id, tunnel_id: tunnel_id) do
    case Svc.Scanner.setup_instances(entity_id, server_id, tunnel_id) do
      {:ok, _, :noop} ->
        []

      {:ok, instances, operation} ->
        Logger.info("ScannerInstances #{operation} for #{entity_id} #{server_id}")
        [ScannerInstancesCreatedEvent.new(instances)]
    end
  end
end
