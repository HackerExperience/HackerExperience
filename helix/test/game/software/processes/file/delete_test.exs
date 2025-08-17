defmodule Game.Process.File.DeleteTest do
  use Test.DBCase, async: true

  alias Game.{File}

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "deletes the File upon completion" do
      server = Setup.server!()
      %{process: process, spec: %{file: file}} = Setup.process(server.id, type: :file_delete)
      assert process.type == :file_delete
      assert process.registry.tgt_file_id == file.id
      DB.commit()

      # This File currently exists in the DB
      Core.with_context(:server, server.id, :read, fn ->
        assert [file] == DB.all(File)
      end)

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, the File is gone
      Core.with_context(:server, server.id, :read, fn ->
        assert [] == DB.all(File)
      end)

      # The FileDeletedEvent will be emitted
      assert event.name == :file_deleted
      assert event.data.file == file
      assert event.data.process == process
    end

    test "fails if Player has no Visibility over File" do
      server = Setup.server!()
      # This `file` is in the same Server but with no visibility
      file = Setup.file!(server.id)
      %{process: process} = Setup.process(server.id, type: :file_delete, spec: [file: file])
      DB.commit()

      assert {{:error, event}, error_log} = with_log(fn -> U.processable_on_complete(process) end)
      assert error_log =~ "Unable to delete file: file_not_found"

      assert event.name == :file_delete_failed
      assert event.data.process == process
      assert event.data.reason == "file_not_found"

      # If we suddenly start having Visibility into the File, then we can complete the process
      Setup.file_visibility!(server.entity_id, server_id: server.id, file_id: file.id)
      assert {:ok, _} = U.processable_on_complete(process)
    end

    test "fails if Player attempts to delete File in another Server without access" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # Player is deleting `File` on the Endpoint. This process already reached its objective
      process =
        Setup.process!(endpoint.id, type: :file_delete, entity_id: entity.id, completed?: true)

      # There is no Tunnel for this remote action
      refute process.registry.src_tunnel_id

      DB.commit()

      assert {{:error, event}, error_log} = with_log(fn -> U.processable_on_complete(process) end)
      assert error_log =~ "Unable to delete file: server_not_belongs"

      assert event.name == :file_delete_failed
      assert event.data.process == process
      assert event.data.reason == "server_not_belongs"

      # If we create a Tunnel between both servers, then we can complete the process
      tunnel =
        Core.with_context(:universe, :write, fn ->
          Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)
        end)

      assert {:ok, _} =
               process
               |> U.Process.add_tunnel_to_process(tunnel.id)
               |> U.processable_on_complete()
    end
  end

  describe "E2E" do
    @tag capture_log: true
    test "upon completion, deletes affected processes and submits events to player(s)", ctx do
      %{player: player, server: server, nip: nip} = Setup.server()

      # Player is deleting `File`. This process already reached its objective
      %{process: proc_delete, spec: %{file: file}} =
        Setup.process(server.id, type: :file_delete, entity_id: player.id, completed?: true)

      # Player is also installing the same `File`. Process hasn't reached objective yet
      %{process: proc_install} =
        Setup.process(server.id, type: :file_install, entity_id: player.id, spec: [file: file])

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 3)

      # Initially we had two running processes
      assert [_, _] = U.get_all_process_registries()

      # Complete the Process
      U.simulate_process_completion(proc_delete)

      # First the Client is notified about the process being complete
      proc_completed_sse = U.wait_sse_event!("process_completed")
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == proc_delete.id

      # Then he is notified about the side-effect of the process completion
      file_deleted_sse = U.wait_sse_event!("file_deleted")
      assert file_deleted_sse.data.nip == nip |> NIP.to_external()
      assert file_deleted_sse.data.file_id |> U.from_eid(player.id) == file.id

      # And then he is notified about `proc_install` being killed
      process_killed_sse = U.wait_sse_event!("process_killed")
      assert process_killed_sse.data.process_id |> U.from_eid(player.id) == proc_install.id
      assert process_killed_sse.data.reason == "killed"

      # Now we have no running processes! `proc_install` was killed due to the source file being deleted
      assert [] == U.get_all_process_registries()
    end

    test "upon completion, generates log entries accordingly" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      %{nip: ap_nip, server: ap} = Setup.server()
      %{nip: en_nip, server: en} = Setup.server()

      # Tunnel: Gateway -> AP -> EN -> Endpoint
      tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip, hops: [ap_nip, en_nip])

      # Player is deleting `File` on the Endpoint. This process already reached its objective
      %{process: proc_delete, spec: %{file: file}} =
        Setup.process(endpoint.id,
          type: :file_delete,
          entity_id: entity.id,
          completed?: true,
          spec: [tunnel: tunnel]
        )

      DB.commit()

      U.simulate_process_completion(proc_delete)

      assert [file_deleted_event] = wait_events_on_server!(endpoint.id, :file_deleted, 1)
      assert file_deleted_event.data.file.id == file.id

      # Log on Gateway -> AP
      assert [log] = U.get_all_logs(gateway.id)
      assert log.type == :file_deleted
      assert log.direction == :to_ap
      assert log.data.nip == ap_nip
      assert log.data.file_name == file.name
      assert log.data.file_ext == "todo"
      assert log.data.file_version == file.version

      # Log on AP -> EN
      assert [log] = U.get_all_logs(ap.id)
      assert log.type == :connection_proxied
      assert log.direction == :hop
      assert log.data.from_nip == gtw_nip
      assert log.data.to_nip == en_nip

      # Log on EN -> AP
      assert [log] = U.get_all_logs(en.id)
      assert log.type == :connection_proxied
      assert log.direction == :hop
      assert log.data.from_nip == ap_nip
      assert log.data.to_nip == endp_nip

      # Log on EN -> Endpoint
      assert [log] = U.get_all_logs(endpoint.id)
      assert log.type == :file_deleted
      assert log.direction == :from_en
      assert log.data.nip == en_nip
      assert log.data.file_name == file.name
      assert log.data.file_ext == "todo"
      assert log.data.file_version == file.version
    end

    @tag capture_log: true
    test "publishes a Failed event if preconditions are not met at completion time", ctx do
      player = Setup.player!()

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # Player is deleting `File` within Endpoint. This process already reached its objective
      %{process: proc_delete, spec: %{file: file}} =
        Setup.process(endpoint.id,
          type: :file_delete,
          entity_id: player.id,
          completed?: true,
          spec: [tunnel: tunnel]
        )

      # The File exists in the Endpoint server, obviously
      assert file.server_id == endpoint.id

      # Moments prior to the completion, the Tunnel was closed!
      # TODO: Move this to a util
      tunnel
      |> Game.Tunnel.update(%{status: :closed})
      |> DB.update!()

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # Complete the Process
      U.simulate_process_completion(proc_delete)

      proc_completed_sse = U.wait_sse_event!("process_completed")
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == proc_delete.id

      file_delete_failed_sse = U.wait_sse_event!("file_delete_failed")
      assert file_delete_failed_sse.data.process_id |> U.from_eid(player.id) == proc_delete.id
      assert file_delete_failed_sse.data.reason == "tunnel_not_found"
    end
  end
end
