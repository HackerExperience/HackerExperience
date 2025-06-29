defmodule Game.Process.AppStore.InstallTest do
  use Test.DBCase, async: true

  alias Game.{File, Installation, Software}

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "creates the file and corresponding installation" do
      server = Setup.server!()
      appstore_config = Software.get(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == "cracker"
      DB.commit()

      # There are no Files or Installations initially
      Core.with_context(:server, server.id, :read, fn ->
        assert [] == DB.all(Installation)
        assert [] == DB.all(File)
      end)

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, we now have this new File present in the server
      Core.begin_context(:server, server.id, :read)
      assert [file] = DB.all(File)
      assert file.name == "Cracker"
      assert file.type == :cracker
      assert file.version == appstore_config[:version] || 10
      assert file.version == appstore_config[:size] || 10

      # We now have an Installation for this particular File
      assert [installation] = DB.all(Installation)

      assert installation.file_id == file.id
      assert installation.file_version == file.version
      assert installation.file_type == file.type

      # The AppStoreInstalledEvent will be emitted
      assert event.name == :appstore_installed
      assert event.data.file == file
      assert event.data.installation == installation
      assert event.data.process == process
    end

    # TODO: With an enhanced Henforcer, perform partial applications of the process depending on
    # the existing server context at the moment the process completes.

    @tag :capture_log
    test "fails if trying to perform the install on someone else's server" do
      entity = Setup.entity_lite!()
      other_server = Setup.server!()

      process =
        Setup.process!(other_server.id,
          entity_id: entity.id,
          type: :appstore_install,
          spec: [software_type: :cracker]
        )

      DB.commit()

      # The Process is in the Other Server but it was started by Entity, who is not the owner
      # Note this is impossible to happen for this particular process, since we validate at the
      # moment the process is created. Still, it's harmless to have an additional layer of defense
      assert process.entity_id == entity.id
      assert process.server_id == other_server.id
      refute other_server.entity_id == entity.id

      assert {:error, event} = U.processable_on_complete(process)

      assert event.name == :appstore_install_failed
      assert event.data.reason == "server_not_belongs"
    end
  end
end
