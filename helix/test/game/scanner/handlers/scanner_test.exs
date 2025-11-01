defmodule Game.Handlers.ScannerTest do
  use Test.DBCase, async: true

  alias Game.Handlers.Scanner, as: ScannerHandler
  alias Game.{Player}

  alias Game.Events.Player.IndexRequested, as: IndexRequestedEvent
  alias Game.Events.Network.TunnelCreated, as: TunnelCreatedEvent

  setup [:with_game_db]

  describe "on_event/1 - IndexRequestedEvent" do
    test "sets up missing instances for all Gateway servers" do
      %{server: server_1, entity: entity} = Setup.server()
      %{server: server_2} = Setup.server(entity: entity)

      event = IndexRequestedEvent.new(Player.ID.new(entity.id))

      # Handler returned two events
      assert {:ok, [_, _] = events} = ScannerHandler.on_event(event.data, event)

      assert event_server_1 = Enum.find(events, &(&1.data.server_id == server_1.id))
      assert event_server_2 = Enum.find(events, &(&1.data.server_id == server_2.id))

      # Events are of type `scanner_instances_created`
      assert event_server_1.name == :scanner_instances_created
      assert event_server_2.name == :scanner_instances_created

      # Each events holds 3 instances that were created (for each server)
      assert [_, _, _] = event_server_1.data.instances
      assert [_, _, _] = event_server_2.data.instances

      # And they reference the correct data
      assert event_server_1.data.server_id == server_1.id
      assert event_server_1.data.entity_id == entity.id
      assert event_server_2.data.server_id == server_2.id
      assert event_server_2.data.entity_id == entity.id

      # We can expect to find these 6 instances in the DB
      assert [_, _, _, _, _, _] = U.get_all_scanner_instances()
    end

    test "performs a no-op when instances already exist" do
      %{entity: entity} = Setup.server()

      event = IndexRequestedEvent.new(Player.ID.new(entity.id))

      # On the first run it returns one event (indicating the instances were set up for `server`)
      assert {:ok, [_]} = ScannerHandler.on_event(event.data, event)

      # On the second run it returns no events (indicating nothing was done)
      assert {:ok, []} = ScannerHandler.on_event(event.data, event)

      # We have 3 instances in the DB
      assert [_, _, _] = U.get_all_scanner_instances()
    end
  end

  describe "on_event/1 - TunnelCreatedEvent" do
    test "sets up missing instances in the Endpoint server" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip)

      tunnel_created_ev = TunnelCreatedEvent.new(tunnel, entity.id, gateway.id, endpoint.id)

      # Handler returned an event
      assert {:ok, [event]} = ScannerHandler.on_event(tunnel_created_ev.data, tunnel_created_ev)

      # ScannerInstancesCreatedEvent contains the expected data
      assert event.name == :scanner_instances_created
      assert [_, _, _] = event.data.instances
      assert event.data.server_id == endpoint.id
      assert event.data.entity_id == entity.id

      # We can expect to find these 3 instances in the DB
      assert [_, _, _] = U.get_all_scanner_instances()

      # Performs a no-op when instances already exist
      assert {:ok, []} == ScannerHandler.on_event(tunnel_created_ev.data, tunnel_created_ev)
      assert [_, _, _] = U.get_all_scanner_instances()
    end
  end
end
