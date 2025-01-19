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
end
