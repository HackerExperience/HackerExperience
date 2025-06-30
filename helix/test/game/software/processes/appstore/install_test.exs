defmodule Game.Process.AppStore.InstallTest do
  use Test.DBCase, async: true

  alias Game.{File, Installation, Software}

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "creates the file and corresponding installation" do
      server = Setup.server!()
      appstore_config = Software.get!(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker
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
      assert file.version == appstore_config.version
      assert file.version == appstore_config.size

      # We now have an Installation for this particular File
      assert [installation] = DB.all(Installation)
      assert installation.file_id == file.id
      assert installation.file_version == file.version
      assert installation.file_type == file.type

      # The AppStoreInstalledEvent will be emitted
      assert event.name == :appstore_installed
      assert event.data.action == :download_and_install
      assert event.data.file == file
      assert event.data.installation == installation
      assert event.data.process == process
    end

    test "creates only the file when a matching installation already exists" do
      server = Setup.server!()
      appstore_config = Software.get!(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker

      # Create a matching File and Installation
      %{file: file, installation: installation} =
        Setup.file(server.id, type: :cracker, version: appstore_config.version, installed?: true)

      DB.commit()

      # Delete the matching File
      Core.with_context(:server, server.id, :write, fn ->
        DB.delete(file)
      end)

      # There is one matching Installation, but no matching File
      Core.with_context(:server, server.id, :write, fn ->
        assert [installation] == DB.all(Installation)
        assert [] == DB.all(File)
      end)

      # With this context, AppStoreInstallProcess should only download the file to the server
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, we now have this new File present in the server
      Core.begin_context(:server, server.id, :read)
      assert [file] = DB.all(File)
      assert file.name == "Cracker"
      assert file.type == :cracker
      assert file.version == appstore_config.version
      assert file.version == appstore_config.size

      # Installation remains unchanged
      assert [installation] == DB.all(Installation)

      # Event contains the expected data
      assert event.data.action == :download_only
      assert event.data.file == file
      refute event.data.installation
    end

    test "creates only the installation when a matching file already exists" do
      server = Setup.server!()
      appstore_config = Software.get!(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker

      # Create a matching File that isn't installed
      file = Setup.file!(server.id, type: :cracker, version: appstore_config.version)

      DB.commit()

      # There is one matching File, but no matching Installation
      Core.with_context(:server, server.id, :write, fn ->
        assert [file] == DB.all(File)
        assert [] == DB.all(Installation)
      end)

      # With this context, AppStoreInstallProcess should only install the existing file
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, we now have this Installation present in the server
      Core.begin_context(:server, server.id, :read)

      assert [installation] = DB.all(Installation)
      assert installation.file_id == file.id
      assert installation.file_version == file.version
      assert installation.file_type == file.type

      # File remains unchanged
      assert [file] == DB.all(File)

      # Event contains the expected data
      assert event.data.action == :install_only
      refute event.data.file
      assert event.data.installation == installation
    end

    test "performs download + install if there are non-matching File and Installations" do
      server = Setup.server!()
      appstore_config = Software.get!(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker

      # Create an "almost matching" File and Installation -- missed the version by 1!
      Setup.file(server.id, type: :cracker, version: appstore_config.version + 1, installed?: true)

      DB.commit()

      # It will still download and install the Software, since the existing one is not a perfect match
      assert {:ok, event} = U.processable_on_complete(process)
      assert event.data.action == :download_and_install

      # Now we have two of each
      Core.with_context(:server, server.id, :write, fn ->
        assert [_, _] = DB.all(File)
        assert [_, _] = DB.all(Installation)
      end)
    end

    @tag :capture_log
    test "fails if there already is a matching file and installation" do
      server = Setup.server!()
      appstore_config = Software.get!(:cracker).config.appstore

      process = Setup.process!(server.id, type: :appstore_install, spec: [software_type: :cracker])
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker

      # Create a matching File and Installation
      Setup.file(server.id, type: :cracker, version: appstore_config.version, installed?: true)

      DB.commit()

      # With this context, AppStoreInstallProcess should return an error -- nothing to be done
      assert {:error, event} = U.processable_on_complete(process)
      assert event.name == :appstore_install_failed
      assert event.data.reason == "file_already_installed"
    end

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
