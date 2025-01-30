defmodule Game.Process.File.TransferTest do
  use Test.DBCase, async: true

  alias Game.Process.File.Transfer, as: FileTransferProcess

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "transfers the File upon completion (download)" do
      gateway = Setup.server!()

      %{process: process, spec: %{file: file, endpoint: endpoint}} =
        Setup.process(gateway.id, type: :file_transfer, spec: [transfer_type: :download])

      # Player is downloading this `file`, in the `endpoint`, via `process`
      assert process.server_id == gateway.id
      assert process.type == :file_transfer
      assert process.data.transfer_type == :download
      assert file.server_id == endpoint.id
      DB.commit()

      # There are no Files in the Gateway initially
      assert [] == U.get_all_files(gateway.id)

      # Simulate Process being completed
      assert {:ok, event} = FileTransferProcess.Processable.on_complete(process)

      # Now there is a new file in the Gateway!
      assert [new_file] = U.get_all_files(gateway.id)

      assert new_file.server_id == gateway.id
      assert_transferred_files_equal(file, new_file)
      refute new_file.inserted_at == file.inserted_at
      refute new_file.updated_at == file.updated_at

      assert event.name == :file_transferred
      assert event.data.file == new_file
      assert event.data.process == process
      assert event.data.transfer_info == {:download, gateway, endpoint}
    end

    test "transfers the File upon completion (upload)" do
      gateway = Setup.server!()

      %{process: process, spec: %{file: file, endpoint: endpoint}} =
        Setup.process(gateway.id, type: :file_transfer, spec: [transfer_type: :upload])

      # Player is uploading this `file`, in the `endpoint`, via `process`
      assert process.server_id == gateway.id
      assert process.type == :file_transfer
      assert process.data.transfer_type == :upload
      assert file.server_id == gateway.id
      DB.commit()

      # There are no Files in the Endpoint initially
      assert [] == U.get_all_files(endpoint.id)

      # Simulate Process being completed
      assert {:ok, event} = FileTransferProcess.Processable.on_complete(process)

      # Now there is a new file in the Endpoint!
      assert [new_file] = U.get_all_files(endpoint.id)

      assert new_file.server_id == endpoint.id
      assert_transferred_files_equal(file, new_file)
      refute new_file.inserted_at == file.inserted_at
      refute new_file.updated_at == file.updated_at

      assert event.name == :file_transferred
      assert event.data.file == new_file
      assert event.data.process == process
      assert event.data.transfer_info == {:upload, gateway, endpoint}
    end

    test "fails if tunnel is closed" do
      gateway = Setup.server!()

      %{process: process, spec: %{tunnel: tunnel}} = Setup.process(gateway.id, type: :file_transfer)

      # Moments prior to the completion, the Tunnel was closed!
      # TODO: Move this to a util
      tunnel
      |> Game.Tunnel.update(%{status: :closed})
      |> DB.update!()

      DB.commit()

      # Simulate Process being completed
      assert {{:error, event}, log} =
               with_log(fn -> FileTransferProcess.Processable.on_complete(process) end)

      assert event.name == :file_transfer_failed
      assert event.data.reason == "tunnel_not_found"
      assert log =~ "Unable to transfer file: tunnel_not_found"
    end

    test "fails if player does not have visibility over file" do
      gateway = Setup.server!()
      endpoint = Setup.server!()

      file = Setup.file!(endpoint.id)

      %{process: process, spec: %{endpoint: endpoint}} =
        Setup.process(gateway.id,
          type: :file_transfer,
          spec: [transfer_type: :download, endpoint: endpoint, file: file]
        )

      # We are downloading `file` from `endpoint`
      assert process.data.transfer_type == :download
      assert process.data.endpoint_id == endpoint.id
      assert process.registry.src_file_id == file.id

      DB.commit()

      # Simulate Process being completed
      assert {{:error, event}, log} =
               with_log(fn -> FileTransferProcess.Processable.on_complete(process) end)

      assert event.name == :file_transfer_failed
      assert event.data.reason == "file_not_found"
      assert log =~ "Unable to transfer file: file_not_found"
    end

    test "fails if file no longer exists" do
      gateway = Setup.server!()

      %{process: process, spec: %{file: file}} = Setup.process(gateway.id, type: :file_transfer)

      # We'll delete the file being used in the Transfer process. Note that ordinarily this would
      # never happen, since the process would receive the SIG_SRC_FILE_DELETED signal and kill
      # itself... but race conditions exist and it's always a good idea to have additional checks
      Core.with_context(:server, file.server_id, :write, fn ->
        assert {:ok, _} = Svc.File.delete(file)
      end)

      DB.commit()

      assert {{:error, event}, log} =
               with_log(fn -> FileTransferProcess.Processable.on_complete(process) end)

      assert event.name == :file_transfer_failed
      assert event.data.reason == "file_not_found"
      assert log =~ "Unable to transfer file: file_not_found"
    end
  end

  describe "Resourceable" do
    test "download uses DLK resource dynamically" do
      %{server: gateway, meta: %{resources: server_resources}} = Setup.server()

      %{process: process, spec: %{file: file}} =
        Setup.process(gateway.id, type: :file_transfer, spec: [transfer_type: :download])

      DB.commit()

      # Run the TOP and wait for an initial allocation on `process`
      U.start_top(gateway.id, wait_for_recalcado: true)

      # Fetch the process again so we can see what its allocated resources look like
      process = Svc.Process.fetch!(gateway.id, by_id: process.id)

      # Process is using 100% of the available DLK in the Server while not using any ULK
      assert_decimal_eq(process.resources.allocated.dlk, server_resources.dlk)
      assert_decimal_eq(process.resources.allocated.ulk, 0)

      # Objective is the file.size (DLK)
      assert_decimal_eq(process.resources.objective.dlk, file.size)
      assert_decimal_eq(process.resources.objective.ulk, 0)
    end

    test "upload uses ULK resource dynamically" do
      %{server: gateway, meta: %{resources: server_resources}} = Setup.server()

      %{process: process, spec: %{file: file}} =
        Setup.process(gateway.id, type: :file_transfer, spec: [transfer_type: :upload])

      DB.commit()

      # Run the TOP and wait for an initial allocation on `process`
      U.start_top(gateway.id, wait_for_recalcado: true)

      # Fetch the process again so we can see what its allocated resources look like
      process = Svc.Process.fetch!(gateway.id, by_id: process.id)

      # Process is using 100% of the available DLK in the Server while not using any ULK
      assert_decimal_eq(process.resources.allocated.ulk, server_resources.ulk)
      assert_decimal_eq(process.resources.allocated.dlk, 0)

      # Objective is the file.size (ULK)
      assert_decimal_eq(process.resources.objective.ulk, file.size)
      assert_decimal_eq(process.resources.objective.dlk, 0)
    end
  end

  describe "E2E - Processable" do
    test "upon completion, transfers the file to the target server (download)", ctx do
      %{player: player, server: gateway} = Setup.player()

      # Player already has a file in the Gateway
      other_file = Setup.file!(gateway.id, visible_by: player.id)

      %{process: process, spec: %{file: file}} =
        Setup.process(gateway.id,
          type: :file_transfer,
          completed?: true,
          spec: [transfer_type: :download]
        )

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # Complete the Process
      U.simulate_process_completion(process)

      # First the Client is notified about the process being complete
      proc_completed_sse = U.wait_sse_event!("process_completed")
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      # Then he is notified about the file transfer event
      file_transferred_sse = U.wait_sse_event!("file_transferred")
      assert file_transferred_sse.data.process_id |> U.from_eid(player.id) == process.id
      new_file_id = file_transferred_sse.data.file_id |> U.from_eid(player.id)

      # Now the player has two files in the Gateway!
      assert gateway_files = [_, _] = U.get_all_files(gateway.id)

      # The `other_file` remains the same
      assert other_file == Enum.find(gateway_files, &(&1.id == other_file.id))

      # And we can find the new file based on the `new_file_id` from the event
      assert new_file = Enum.find(gateway_files, &(&1.id == new_file_id))

      # The files are essentially the same, minus the things expected to change after a transfer
      assert_transferred_files_equal(file, new_file)
    end

    test "upon completion, transfers the file to the target server (upload)", ctx do
      %{player: player, server: gateway} = Setup.player()

      %{process: process, spec: %{file: file, endpoint: endpoint}} =
        Setup.process(gateway.id,
          type: :file_transfer,
          completed?: true,
          spec: [transfer_type: :upload]
        )

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # Complete the Process
      U.simulate_process_completion(process)

      # First the Client is notified about the process being complete
      proc_completed_sse = U.wait_sse_event!("process_completed")
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      # Then he is notified about the file transfer event
      file_transferred_sse = U.wait_sse_event!("file_transferred")
      assert file_transferred_sse.data.process_id |> U.from_eid(player.id) == process.id

      # Now the endpoint has a new file!
      assert [new_file] = U.get_all_files(endpoint.id)

      # The files are essentially the same, minus the things expected to change after a transfer
      assert_transferred_files_equal(file, new_file)
    end

    test "upon completion, generates the log entries accordingly" do
      %{nip: gtw_nip, server: gateway, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      %{process: process, spec: %{file: file}} =
        Setup.process(gateway.id,
          entity_id: entity.id,
          type: :file_transfer,
          completed?: true,
          spec: [tunnel: tunnel, endpoint: endpoint]
        )

      DB.commit()

      # Complete the process and wait for the FileTransferredEvent to be processed
      U.simulate_process_completion(process)
      assert [_] = wait_events_on_server!(gateway.id, :file_transferred, 1)

      expected_log_type =
        case process.data.transfer_type do
          :download -> :file_downloaded
          :upload -> :file_uploaded
        end

      # Log on Gateway -> AP (Endpoint)
      assert [log] = U.get_all_logs(gateway.id)
      assert log.type == expected_log_type
      assert log.direction == :to_ap
      assert log.data.nip == endp_nip
      assert log.data.file_name == file.name
      assert log.data.file_ext == "todo"
      assert log.data.file_version == file.version

      # Log on EN (Gateway) -> Endpoint
      assert [log] = U.get_all_logs(endpoint.id)
      assert log.type == expected_log_type
      assert log.direction == :from_en
      assert log.data.nip == gtw_nip
      assert log.data.file_name == file.name
      assert log.data.file_ext == "todo"
      assert log.data.file_version == file.version
    end
  end

  describe "E2E - Signalable" do
    test "process is killed if file being transferred gets deleted", ctx do
      %{player: player, server: gateway} = Setup.player()

      %{process: transfer_process, spec: %{file: file}} =
        Setup.process(gateway.id, type: :file_transfer)

      DB.commit()

      target_nip = Svc.NetworkConnection.fetch!(by_server_id: file.server_id).nip

      U.start_sse_listener(ctx, player, total_expected_events: 1)

      # FileTransferProcess is running nicely
      assert [_] = U.get_all_processes(gateway.id)

      Core.begin_context(:universe, :write)

      # Now we'll simulate a third party "other" deleting this File
      %{entity: other_entity, nip: other_nip} = Setup.server()

      # `other_server` has access to the Server where the File is and has visibility over the File
      other_tunnel = Setup.tunnel!(source_nip: other_nip, target_nip: target_nip)
      Setup.file_visibility!(other_entity.id, server_id: file.server_id, file_id: file.id)

      # And now "other" can start a FileDeleteProcess
      file_delete_process =
        Setup.process!(file.server_id,
          entity_id: other_entity.id,
          type: :file_delete,
          completed?: true,
          spec: [file: file, tunnel: other_tunnel]
        )

      DB.commit()

      U.simulate_process_completion(file_delete_process)

      # Player eventually received a ProcessKilledEvent
      process_killed_event = U.wait_sse_event!("process_killed")
      assert process_killed_event.data.process_id |> U.from_eid(player.id) == transfer_process.id
      assert process_killed_event.data.reason == "killed"

      # No more processes are running in the Gateway server
      assert [] = U.get_all_processes(gateway.id)
    end
  end

  defp assert_transferred_files_equal(previous_file, new_file) do
    copied_attributes = [:type, :name, :version, :size]
    assert Map.take(previous_file, copied_attributes) == Map.take(new_file, copied_attributes)
  end
end
