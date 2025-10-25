defmodule Game.Handlers.Scanner do
  @behaviour Core.Event.Handler.Behaviour

  require Logger

  alias Game.Services, as: Svc
  alias Game.{Entity}

  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent
  alias Game.Events.Player.IndexRequested, as: IndexRequestedEvent
  alias Game.Events.Scanner.InstancesCreated, as: ScannerInstancesCreatedEvent

  # Make sure ScannerInstances are set up every time a player logs in
  def on_event(%IndexRequestedEvent{player_id: player_id}, _) do
    gateways = Svc.Server.list(by_entity_id: player_id)
    entity_id = Entity.ID.new(player_id)

    events =
      Enum.reduce(gateways, [], fn %{id: server_id}, acc ->
        case Svc.Scanner.setup_instances(entity_id, server_id, nil) do
          {:ok, _, :noop} ->
            acc

          {:ok, instances, operation} ->
            Logger.info("ScannerInstances #{operation} for #{entity_id} #{server_id}")
            [ScannerInstancesCreatedEvent.new(instances) | acc]
        end
      end)

    {:ok, events}
  end

  # Make sure ScannerInstances are set up every time a player logs into a remote server
  def on_event(%TunnelCreatedEvent{}, _) do
    # TODO
    :ok
  end
end
