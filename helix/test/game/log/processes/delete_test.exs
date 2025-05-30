defmodule Game.Process.Log.DeleteTest do
  use Test.DBCase, async: true

  alias Game.Process.Log.Delete, as: LogDeleteProcess

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "deletes the Log upon completion" do
      %{server: server, entity: entity} = Setup.server()

      log_rev_1 = Setup.log!(server.id, visible_by: entity.id)
      log_rev_2 = Setup.log!(server.id, id: log_rev_1.id, revision_id: 2, visible_by: entity.id)

      process =
        Setup.process!(server.id, entity_id: entity.id, type: :log_delete, spec: [log: log_rev_2])

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = LogDeleteProcess.Processable.on_complete(process)

      Core.begin_context(:server, server.id, :read)

      # After the process has completed, the Log and all its revisions were flagged as deleted
      log_rev_1 = DB.reload!(log_rev_1)
      assert log_rev_1.deleted_at
      assert log_rev_1.deleted_by == entity.id

      log_rev_2 = DB.reload!(log_rev_2)
      assert log_rev_2.deleted_at == log_rev_2.deleted_at
      assert log_rev_2.deleted_by == entity.id

      # The LogDeletedEvent will be emitted
      assert event.name == :log_deleted
      assert event.data.log == log_rev_2
      assert event.data.process == process

      assert event.relay.source == :process
      assert event.relay.server_id == server.id
      assert event.relay.process_id == process.id
    end

    test "deletes the Log upon completion (remote)" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()

      # Log exists on the Endpoint as is visible by the player
      log = Setup.log!(endpoint.id, visible_by: entity.id)

      # There is a valid tunnel between both servers
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      process =
        Setup.process!(endpoint.id,
          entity_id: entity.id,
          type: :log_delete,
          spec: [log: log, tunnel: tunnel]
        )

      assert process.registry.tgt_log_id == log.id
      assert process.registry.src_tunnel_id == tunnel.id

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = LogDeleteProcess.Processable.on_complete(process)

      assert event.name == :log_deleted
      assert event.data.log.id == log.id
      assert event.relay.server_id == endpoint.id

      Core.begin_context(:server, endpoint.id, :read)

      # The log was deleted
      log = DB.reload!(log)
      assert log.deleted_at
      assert log.deleted_by == entity.id
    end

    test "fails if Log is already deleted" do
      %{server: server, entity: entity} = Setup.server()

      log = Setup.log!(server.id, visible_by: entity.id)

      process =
        Setup.process!(server.id, entity_id: entity.id, type: :log_delete, spec: [log: log])

      # Log was deleted while process was running
      assert :ok == Svc.Log.delete(log, entity.id)

      DB.commit()

      assert {{:error, event}, error_log} =
               with_log(fn -> LogDeleteProcess.Processable.on_complete(process) end)

      assert error_log =~ "Unable to delete log: log_already_deleted"

      # A LogDeleteFailedEvent was returned
      assert event.name == :log_delete_failed
      assert event.data.reason == "log_already_deleted"
    end

    test "fails if Player has no visibility over Log" do
      %{server: server, entity: entity} = Setup.server()

      log = Setup.log!(server.id)
      process = Setup.process!(server.id, entity_id: entity.id, type: :log_delete, spec: [log: log])
      DB.commit()

      assert {{:error, event}, error_log} =
               with_log(fn -> LogDeleteProcess.Processable.on_complete(process) end)

      assert error_log =~ "Unable to delete log: log_not_found"

      # A LogDeleteFailedEvent was returned
      assert event.name == :log_delete_failed
      assert event.data.reason == "log_not_found"

      # The log remained unchanged in the database
      Core.begin_context(:server, server.id, :read)
      assert log == DB.reload(log)
    end

    test "fails if Tunnel is closed" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()

      # There is a tunnel initially
      log = Setup.log!(endpoint.id, visible_by: entity.id)
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      process =
        Setup.process!(endpoint.id,
          entity_id: entity.id,
          type: :log_delete,
          spec: [log: log, tunnel: tunnel]
        )

      # Moments prior to the completion, the Tunnel was closed!
      # TODO: Move this to a util (grep for duplicates)
      tunnel
      |> Game.Tunnel.update(%{status: :closed})
      |> DB.update!()

      DB.commit()

      # Simulate Process being completed
      assert {{:error, event}, error_log} =
               with_log(fn -> LogDeleteProcess.Processable.on_complete(process) end)

      assert event.name == :log_delete_failed
      assert event.data.reason == "tunnel_not_found"
      assert error_log =~ "Unable to delete log: tunnel_not_found"
    end

    test "fails if process is missing a Tunnel" do
      entity = Setup.entity!()
      endpoint = Setup.server!()

      log = Setup.log!(endpoint.id, visible_by: entity.id)

      # I don't think this is even possible (Endpoint would never allow this being created)
      process =
        Setup.process!(endpoint.id,
          entity_id: entity.id,
          type: :log_delete,
          spec: [log: log, tunnel: nil]
        )

      DB.commit()

      # Simulate Process being completed
      assert {{:error, event}, error_log} =
               with_log(fn -> LogDeleteProcess.Processable.on_complete(process) end)

      assert event.name == :log_delete_failed
      assert event.data.reason == "server_not_belongs"
      assert error_log =~ "Unable to delete log: server_not_belongs"
    end
  end

  describe "E2E - Processable" do
    test "upon completion, deletes the log", ctx do
      %{server: server, entity: entity, player: player, nip: nip} = Setup.server()

      log_rev_1 = Setup.log!(server.id, visible_by: entity.id)
      log_rev_2 = Setup.log!(server.id, id: log_rev_1.id, revision_id: 2, visible_by: entity.id)

      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :log_delete,
          completed?: true,
          spec: [log: log_rev_2]
        )

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # Complete the Process
      U.simulate_process_completion(process)

      # SSE events were published
      proc_completed_sse = U.wait_sse_event!("process_completed")
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      log_deleted_sse = U.wait_sse_event!("log_deleted")
      assert log_deleted_sse.data.nip == nip |> NIP.to_external()
      assert log_deleted_sse.data.process_id |> U.from_eid(player.id) == process.id
      assert log_deleted_sse.data.log_id |> U.from_eid(player.id) == log_rev_2.id

      # All revisions were deleted
      Core.begin_context(:server, server.id, :read)
      assert DB.reload!(log_rev_1).deleted_at
      assert DB.reload!(log_rev_2).deleted_at
    end

    # TODO: Emit the LogDeletedEvent to every player with visibility on the log
  end

  describe "E2E - Signalable" do
    test "process is killed if log being deleted gets deleted by another process", ctx do
      %{nip: gtw_nip, server: server, entity: entity, player: player} = Setup.server()
      %{nip: endp_nip, entity: other_entity, player: other_player} = Setup.server()

      log_rev_1 = Setup.log!(server.id, visible_by: entity.id)

      log_rev_2 =
        Setup.log!(server.id, id: log_rev_1.id, revision_id: 2, visible_by: other_entity.id)

      tunnel = Setup.tunnel!(source_nip: endp_nip, target_nip: gtw_nip)

      # `entity` is deleting the log (via `log_rev_1`)
      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :log_delete,
          spec: [log: log_rev_1]
        )

      # `other_entity` is deleting the log (via `log_rev_2`)
      other_process =
        Setup.process!(server.id,
          entity_id: other_entity.id,
          type: :log_delete,
          completed?: true,
          spec: [log: log_rev_2, tunnel: tunnel]
        )

      DB.commit()

      U.start_sse_listener(ctx, player)
      U.start_sse_listener(ctx, other_player, total_expected_events: 2)

      U.simulate_process_completion(other_process)

      process_killed_event = U.wait_sse_event!("process_killed")
      assert process_killed_event.data.process_id |> U.from_eid(player.id) == process.id
      assert process_killed_event.data.reason == "killed"

      process_completed_event = U.wait_sse_event!("process_completed")

      assert process_completed_event.data.process_id |> U.from_eid(other_player.id) ==
               other_process.id

      assert process_completed_event.data.nip == gtw_nip |> NIP.to_external()
      assert process_completed_event.data.type == "log_delete"
      assert process_completed_event.data.data =~ "\"log_id\":"

      log_deleted_event = U.wait_sse_event!("log_deleted")
      assert log_deleted_event.data.log_id |> U.from_eid(other_player.id) == log_rev_2.id
    end
  end
end
