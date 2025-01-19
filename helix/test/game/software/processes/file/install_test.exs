defmodule Game.Process.File.InstallTest do
  use Test.DBCase, async: true

  alias Game.{Installation}

  alias Game.Process.File.Install, as: FileInstallProcess

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
      assert {:ok, [event]} = FileInstallProcess.Processable.on_complete(process)

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
  end
end
