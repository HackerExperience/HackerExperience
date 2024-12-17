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
          server_id: server.id,
          type: :local_login,
          data: %{}
        }

      # Emit the `Test.LoggableEvent`, which will relay the given `log_map` for Loggable
      event = Test.LoggableEvent.new(log_map)
      capture_log(fn -> Event.emit([event]) end)

      # The log was correctly created in the server
      Core.with_context(:server, server.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :local_login
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

    test "works with remote log (direct Gateway -> Endpoint route)" do
      # There exists a Gateway -> Endpoint tunnel (with no intermediary servers)
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      DB.commit()
      Core.begin_context(:universe, :read)

      # LogMap for a remote log
      log_map =
        %{
          entity_id: entity.id,
          gateway_id: gateway.id,
          endpoint_id: endpoint.id,
          tunnel_id: tunnel.id,
          type_gateway: :remote_login_gateway,
          data_gateway: %{nip: "$access_point"},
          type_endpoint: :remote_login_endpoint,
          data_endpoint: %{nip: "$exit_node"}
        }

      # Emit the Event with the above `log_map` for Loggable to process
      event = Test.LoggableEvent.new(log_map)
      capture_log(fn -> Event.emit([event]) end)

      # The logs were created correctly in the gateway...
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :remote_login_gateway
        assert log.data.nip == endp_nip
      end)

      # And in the endpoint...
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [log] = DB.all(Log)
        assert log.type == :remote_login_endpoint
        assert log.data.nip == gtw_nip
      end)

      # Player has visibility on both logs
      Core.with_context(:player, entity.id, :read, fn ->
        assert [_, _] = DB.all(LogVisibility)
      end)
    end

    @tag :skip
    test "works with remote log (with intermediary hops)"
  end
end
