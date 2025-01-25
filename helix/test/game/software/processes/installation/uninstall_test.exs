defmodule Game.Process.Installation.UninstallTest do
  use Test.DBCase, async: true

  alias Game.{Installation}

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
  end
end
