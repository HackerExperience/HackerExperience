defmodule Game.Process.File.InstallTest do
  use Test.DBCase, async: true

  alias Game.{Installation}

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "creates an Installation for the File" do
      server = Setup.server!()
      %{process: process, spec: %{file: file}} = Setup.process(server.id, type: :file_install)
      assert process.type == :file_install
      assert process.registry.src_file_id == file.id
      DB.commit()

      # There are no Installations initially
      Core.with_context(:server, server.id, :read, fn ->
        assert [] == DB.all(Installation)
      end)

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, we now do have an Installation for this particular File
      Core.begin_context(:server, server.id, :read)
      assert [installation] = DB.all(Installation)

      assert installation.file_id == file.id
      assert installation.file_version == file.version
      assert installation.file_type == file.type
      assert installation.memory_usage == 5

      # The FileInstalledEvent will be emitted
      assert event.name == :file_installed
      assert event.data.file == file
      assert event.data.installation == installation
      assert event.data.process == process
    end

    test "fails if Player has no Visibility over File" do
      server = Setup.server!()
      # This `file` is in the same Server but with no visibility
      file = Setup.file!(server.id)
      %{process: process} = Setup.process(server.id, type: :file_install, spec: [file: file])
      DB.commit()

      assert {{:error, event}, error_log} = with_log(fn -> U.processable_on_complete(process) end)
      assert error_log =~ "Unable to install file: file_not_found"

      assert event.name == :file_install_failed
      assert event.data.process == process
      assert event.data.reason == "file_not_found"

      # If we suddenly start having Visibility into the File, then we can complete the process
      Setup.file_visibility!(server.entity_id, server_id: server.id, file_id: file.id)
      assert {:ok, _} = U.processable_on_complete(process)
    end

    @tag :capture_log
    test "fails if trying to perform an installation on someone else's server" do
      entity = Setup.entity_lite!()
      other_server = Setup.server!()
      process = Setup.process!(other_server.id, entity_id: entity.id, type: :file_install)
      DB.commit()

      # The Process is in the Other Server but it was started by Entity, who is not the owner
      # Note this is impossible to happen for this particular process, since we validate at the
      # moment the process is created. Still, it's harmless to have an additional layer of defense
      assert process.entity_id == entity.id
      assert process.server_id == other_server.id
      refute other_server.entity_id == entity.id

      assert {:error, event} = U.processable_on_complete(process)

      assert event.name == :file_install_failed
      assert event.data.reason == "server_not_belongs"
    end
  end

  describe "E2E" do
    test "upon completion, installs the file", ctx do
      %{player: player, server: server, nip: nip} = Setup.server()

      # Player is installing `File`. This process already reached its objective
      %{process: process, spec: %{file: file}} =
        Setup.process(server.id, type: :file_install, completed?: true)

      DB.commit()

      U.start_sse_listener(ctx, player, total_expected_events: 2)

      # There are no Installations initially
      Core.with_context(:server, server.id, :read, fn ->
        assert [] == DB.all(Installation)
      end)

      # Complete the Process
      U.simulate_process_completion(process)

      # First the Client is notified about the process being complete
      process_completed_sse = U.wait_sse_event!("process_completed")
      assert process_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      # Then it is notified about the side-effect of the process completion
      file_installed_sse = U.wait_sse_event!("file_installed")
      assert file_installed_sse.data.nip == nip |> NIP.to_external()
      assert file_installed_sse.data.file_name == file.name

      # Now we have one installation for this file
      Core.with_context(:server, server.id, :read, fn ->
        assert [installation] = DB.all(Installation)
        assert file_installed_sse.data.installation_id |> U.from_eid(player.id) == installation.id
        assert installation.file_id == file.id
      end)
    end
  end
end
