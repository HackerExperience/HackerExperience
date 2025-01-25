defmodule Game.Process.File.TransferTest do
  use Test.DBCase, async: true

  alias Game.Process.File.Transfer, as: FileTransferProcess

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "transfer the File upon completion (download)" do
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
      assert new_file.type == file.type
      assert new_file.size == file.size
      assert new_file.version == file.version
      refute new_file.inserted_at == file.inserted_at
      refute new_file.updated_at == file.updated_at

      assert event.name == :file_transferred
      assert event.data.file == new_file
      assert event.data.process == process
      assert event.data.transfer_info == {:download, gateway, endpoint}
    end

    test "transfer the File upon completion (upload)" do
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
      assert new_file.type == file.type
      assert new_file.size == file.size
      assert new_file.version == file.version
      refute new_file.inserted_at == file.inserted_at
      refute new_file.updated_at == file.updated_at

      assert event.name == :file_transferred
      assert event.data.file == new_file
      assert event.data.process == process
      assert event.data.transfer_info == {:upload, gateway, endpoint}
    end
  end

  # Parei aqui; falta testar os erros e comitar
end
