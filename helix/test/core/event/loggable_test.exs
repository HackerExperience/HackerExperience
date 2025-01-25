defmodule Core.Event.LoggableTest do
  use Test.DBCase, async: true
  alias Core.Event
  alias Game.{Log, LogVisibility}

  setup [:with_game_db]

  describe "Loggable trigger" do
    test "works with local log" do
      %{server: server, entity: entity} = Setup.server()

      # LogMap for a local log
      log_map =
        %{
          entity_id: entity.id,
          target_id: server.id,
          type: :server_login,
          data: %{gateway: %{}},
          tunnel_id: nil
        }

      # Emit the `Test.LoggableEvent`, which will relay the given `log_map` for Loggable
      capture_log(fn ->
        event = Test.LoggableEvent.new(log_map)
        Event.emit([event])
      end)

      # The log was correctly created in the server
      Core.with_context(:server, server.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :self
        assert log.data == %Log.Data.EmptyData{}
        assert log.server_id == server.id
        assert log.revision_id == 1
      end)

      # It has the correct visibility too
      Core.with_context(:player, entity.id, :read, fn ->
        assert [log_visibility] = DB.all(LogVisibility)
        assert log_visibility.server_id == server.id
        assert log_visibility.entity_id == entity.id
      end)
    end

    @tag :capture_log
    test "works with remote log (direct Gateway -> Endpoint route)" do
      # There exists a Gateway -> Endpoint tunnel (with no intermediary servers)
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      DB.commit()

      # LogMap for a remote log
      log_map =
        %{
          entity_id: entity.id,
          target_id: endpoint.id,
          tunnel_id: tunnel.id,
          type: :server_login,
          data: %{
            gateway: %{nip: "$access_point"},
            endpoint: %{nip: "$exit_node"}
          }
        }

      # Emit the Event with the above `log_map` for Loggable to process
      event = Test.LoggableEvent.new(log_map)
      Event.emit([event])

      # The logs were created correctly in the gateway...
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :to_ap
        assert log.data.nip == endp_nip
      end)

      # And in the endpoint
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :from_en
        assert log.data.nip == gtw_nip
      end)

      # Player has visibility on both logs
      Core.with_context(:player, entity.id, :read, fn ->
        assert [_, _] = DB.all(LogVisibility)
      end)
    end

    test "works with remote log (with 1 intermediary hop)" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      %{nip: hop_nip, server: hop} = Setup.server()

      # Tunnel: Gateway -> Hop -> Endpoint. In this scenario, hop is both Access Point and Exit Node
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip, hops: [hop_nip])

      DB.commit()

      # LogMap for the remote log
      log_map =
        %{
          entity_id: entity.id,
          target_id: endpoint.id,
          tunnel_id: tunnel.id,
          type: :server_login,
          data: %{
            gateway: %{nip: "$access_point"},
            endpoint: %{nip: "$exit_node"}
          }
        }

      # Emit the Event with the above `log_map` for Loggable to process
      capture_log(fn ->
        event = Test.LoggableEvent.new(log_map)
        Event.emit([event])
      end)

      # The logs were created in the gateway...
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :to_ap
        # Notice the outgoing address is the hop (AP)
        assert log.data.nip == hop_nip
      end)

      # And in the endpoint
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :from_en
        # Notice the incoming address is the hop (EN)
        assert log.data.nip == hop_nip
      end)

      # The hop had a log added to it too
      Core.with_context(:server, hop.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :connection_proxied
        assert log.direction == :hop
        # Notice that in this scenario hop acts as AccessPoint and Exit Node
        assert log.data.from_nip == gtw_nip
        assert log.data.to_nip == endp_nip
      end)
    end

    test "works with remote log (with 2 intermediary hops)" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server_full()
      %{nip: endp_nip, server: endpoint} = Setup.server_full()
      %{nip: access_point_nip, server: access_point} = Setup.server_full()
      %{nip: exit_node_nip, server: exit_node} = Setup.server_full()

      # Tunnel: Gateway -> AccessPoint -> ExitNode -> Endpoint
      tunnel =
        Setup.tunnel!(
          source_nip: gtw_nip,
          target_nip: endp_nip,
          hops: [access_point_nip, exit_node_nip]
        )

      DB.commit()

      # LogMap for the remote log
      log_map =
        %{
          entity_id: entity.id,
          target_id: endpoint.id,
          tunnel_id: tunnel.id,
          type: :server_login,
          data: %{
            gateway: %{nip: "$access_point"},
            endpoint: %{nip: "$exit_node"}
          }
        }

      # Emit the Event with the above `log_map` for Loggable to process
      capture_log(fn ->
        event = Test.LoggableEvent.new(log_map)
        Event.emit([event])
      end)

      # The logs were created in the gateway...
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :to_ap
        assert log.data.nip == access_point_nip
      end)

      # And in the endpoint
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :server_login
        assert log.direction == :from_en
        assert log.data.nip == exit_node_nip
      end)

      # The hops had a log added to it too
      Core.with_context(:server, access_point.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :connection_proxied
        assert log.direction == :hop
        # By definition, AccessPoint is the hop in which the Gateway IP address shows up
        assert log.data.from_nip == gtw_nip
        assert log.data.to_nip == exit_node_nip
      end)

      Core.with_context(:server, exit_node.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :connection_proxied
        assert log.direction == :hop
        # By definition, ExitNode is the hop in which the Endpoint IP address shows up
        assert log.data.from_nip == access_point_nip
        assert log.data.to_nip == endp_nip
      end)
    end
  end
end
