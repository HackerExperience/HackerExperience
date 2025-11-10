defmodule Game.Process.Installation.UninstallTest do
  use Test.DBCase, async: true

  alias Game.{File, Installation}

  alias Game.Process.Installation.Uninstall, as: InstallationUninstallProcess

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "Uninstalls the Installation" do
      server = Setup.server!()

      %{process: process, spec: %{installation: installation}} =
        Setup.process(server.id, type: :installation_uninstall)

      assert process.type == :installation_uninstall
      assert process.registry.tgt_installation_id == installation.id
      DB.commit()

      # There is an Installation initially
      Core.with_context(:server, server.id, :read, fn ->
        assert [_] = DB.all(Installation)
      end)

      # Simulate Process being completed
      assert {:ok, event} = InstallationUninstallProcess.Processable.on_complete(process)

      # After the process has completed, the installation has been removed
      Core.begin_context(:server, server.id, :read)
      assert [] == DB.all(Installation)

      # The InstallationUninstalledEvent will be emitted
      assert event.name == :installation_uninstalled
      assert event.data.installation == installation
      assert event.data.process == process
    end

    test "fails if Installation does not exist" do
      server = Setup.server!()

      %{process: process, spec: %{installation: installation}} =
        Setup.process(server.id, type: :installation_uninstall)

      DB.commit()

      # Let's uninstall the installation manually, before the process gets a chance to complete
      Core.with_context(:server, server.id, :write, fn ->
        Svc.Installation.uninstall(installation)
      end)

      assert {{:error, event}, log} =
               with_log(fn -> InstallationUninstallProcess.Processable.on_complete(process) end)

      assert event.name == :installation_uninstall_failed
      assert event.data.process == process
      assert event.data.reason == "installation_not_found"
      assert log =~ "Unable to uninstall installation: installation_not_found"
    end

    @tag :capture_log
    test "fails if trying to uninstall Installation from someone else" do
      entity = Setup.entity_lite!()
      other_server = Setup.server!()
      process = Setup.process!(other_server.id, entity_id: entity.id, type: :installation_uninstall)
      DB.commit()

      # The Process is in the Other Server but it was started by Entity, who is not the owner
      # Note this is impossible to happen for this particular process, since we validate at the
      # moment the process is created. Still, it's harmless to have an additional layer of defense
      assert process.entity_id == entity.id
      assert process.server_id == other_server.id
      refute other_server.entity_id == entity.id

      assert {:error, event} = InstallationUninstallProcess.Processable.on_complete(process)

      assert event.name == :installation_uninstall_failed
      assert event.data.reason == "server_not_belongs"
    end
  end

  describe "E2E" do
    test "upon completion, uninstalls the installation", ctx do
      %{player: player, server: server, nip: nip} = Setup.server()

      %{process: process, spec: %{installation: installation, file: file}} =
        Setup.process(server.id, type: :installation_uninstall, completed?: true)

      assert process.type == :installation_uninstall
      assert process.registry.tgt_installation_id == installation.id
      DB.commit()

      # There is an Installation initially
      Core.with_context(:server, server.id, :read, fn ->
        assert [installation] == DB.all(Installation)
        assert installation.file_id == file.id
      end)

      U.start_sse_listener(ctx, player, last_event: :installation_uninstalled)

      # Complete the Process
      U.simulate_process_completion(process)

      # First the Client is notified about the process being complete
      process_completed_sse = U.wait_sse_event!(:process_completed)
      assert process_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      # Then it is notified about the side-effect of the process completion
      inst_uninstalled_sse = U.wait_sse_event!(:installation_uninstalled)
      assert inst_uninstalled_sse.data.nip == nip |> NIP.to_external()
      assert inst_uninstalled_sse.data.installation_id |> U.from_eid(player.id) == installation.id

      # Now we no longer have any installation in the server, but the file is still there
      Core.with_context(:server, server.id, :read, fn ->
        assert [] == DB.all(Installation)
        assert [file] == DB.all(File)
      end)
    end
  end
end
