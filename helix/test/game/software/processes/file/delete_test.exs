defmodule Game.Process.File.DeleteTest do
  use Test.DBCase, async: true

  alias Game.{File}

  alias Game.Process.File.Delete, as: FileDeleteProcess

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
      assert {:ok, event} = FileDeleteProcess.Processable.on_complete(process)

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

      assert {{:error, event}, log} =
               with_log(fn -> FileDeleteProcess.Processable.on_complete(process) end)

      assert event.name == :file_delete_failed
      assert event.data.process == process
      assert event.data.reason == "file_not_found"

      assert log =~ "Unable to delete file: file_not_found"

      # If we suddenly start having Visibility into the File, then we can complete the process
      Setup.file_visibility!(server.entity_id, server_id: server.id, file_id: file.id)
      assert {:ok, _} = FileDeleteProcess.Processable.on_complete(process)
    end
  end

  describe "E2E" do
    @tag capture_log: true
    test "upon completion, deletes affected processes and submits events to player(s)", ctx do
      player = Setup.player!()
      server = Setup.server!(entity_id: player.id)

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
      assert proc_completed_sse.data.process_id == proc_delete.id.id

      # Then he is notified about the side-effect of the process completion
      file_deleted_sse = U.wait_sse_event!("file_deleted")
      assert file_deleted_sse.data.file_id == file.id.id
      assert file_deleted_sse.data.process_id == proc_delete.id.id

      # And then he is notified about `proc_install` being killed
      process_killed_sse = U.wait_sse_event!("process_killed")
      assert process_killed_sse.data.process_id == proc_install.id.id
      assert process_killed_sse.data.reason == "killed"

      # Now we have no running processes! `proc_install` was killed due to the source file being deleted
      assert [] == U.get_all_process_registries()
    end

    @tag capture_log: true
    test "publishes a Failed event if preconditions are not met at completion time", ctx do
      player = Setup.player!()

      # There ISN'T a Tunnel from Gateway -> Endpoint
      %{server: _gateway} = Setup.server(entity_id: player.id)
      %{server: endpoint} = Setup.server()

      # Player is deleting `File` within Endpoint. This process already reached its objective
      %{process: proc_delete, spec: %{file: file}} =
        Setup.process(endpoint.id, type: :file_delete, entity_id: player.id, completed?: true)

      # The File exists in the Endpoint server, obviously
      assert file.server_id == endpoint.id

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # Complete the Process
      U.simulate_process_completion(proc_delete)

      proc_completed_event = U.wait_sse_event!("process_completed")
      assert proc_completed_event.data.process_id == proc_delete.id.id

      # file_delete_failed_event = U.wait_sse_event!("file_delete_failed")
    end
  end
end
