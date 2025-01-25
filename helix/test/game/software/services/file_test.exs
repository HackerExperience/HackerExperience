defmodule Game.Services.FileTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  describe "transfer/2" do
    test "transfers the file (download)" do
      gateway = Setup.server!()
      endpoint = Setup.server!()

      # `file` is in the Endpoint
      file = Setup.file!(endpoint.id)
      DB.commit()

      Core.begin_context(:server, gateway.id, :write)

      assert {:ok, new_file} = Svc.File.transfer(file, {:download, gateway, endpoint})

      # The new file was created in the Gateway (i.e. the Gateway downloaded the file)
      assert new_file.server_id == gateway.id

      # The new File is essentially a copy of the previous file
      assert new_file.type == file.type
      assert new_file.version == file.version
      assert new_file.size == file.size
    end

    test "transfers the file (upload)" do
      gateway = Setup.server!()
      endpoint = Setup.server!()

      # `file` is in the Gateway
      file = Setup.file!(gateway.id)
      DB.commit()

      Core.begin_context(:server, endpoint.id, :write)
      assert {:ok, new_file} = Svc.File.transfer(file, {:upload, gateway, endpoint})

      # The new file was created in the Endpoint (i.e. the Gateway uploaded the file)
      assert new_file.server_id == endpoint.id

      # The new File is essentially a copy of the previous file
      assert new_file.type == file.type
      assert new_file.version == file.version
      assert new_file.size == file.size
    end

    test "raises if Server context is different than file destination" do
      gateway = Setup.server!()
      endpoint = Setup.server!()
      file_gtw = Setup.file!(gateway.id)
      file_endp = Setup.file!(endpoint.id)

      %{message: error} =
        assert_raise RuntimeError, fn ->
          # This should raise because we are trying to upload the gateway file into the endpoint (so
          # far so good) but the DB Context in which we are writing is the Gateway. No! The new file
          # should be written in the Endpoint context.
          Core.with_context(:server, gateway.id, :write, fn ->
            Svc.File.transfer(file_gtw, {:upload, gateway, endpoint})
          end)
        end

      assert error =~ "Bad context: expected server_id #{endpoint.id.id}, got: #{gateway.id.id}"

      # Same issue happens if we try to write to the Endpoint context when it should be the Gateway
      # in the event of a file download
      %{message: error} =
        assert_raise RuntimeError, fn ->
          Core.with_context(:server, endpoint.id, :write, fn ->
            Svc.File.transfer(file_endp, {:download, gateway, endpoint})
          end)
        end

      assert error =~ "Bad context: expected server_id #{gateway.id.id}, got: #{endpoint.id.id}"
    end

    test "raises if File belongs to an unexpected Server" do
      gateway = Setup.server!()
      endpoint = Setup.server!()
      file_gtw = Setup.file!(gateway.id)
      file_endp = Setup.file!(endpoint.id)
      other_file = Setup.file!(Setup.server!().id)

      do_transfer = fn file, transfer_info ->
        Svc.File.transfer(file, transfer_info)
      end

      # Can't download a file that is on my own server
      assert_raise MatchError, fn -> do_transfer.(file_gtw, {:download, gateway, endpoint}) end

      # Can't upload a file that is on the endpoint
      assert_raise MatchError, fn -> do_transfer.(file_endp, {:upload, gateway, endpoint}) end

      # Can't download/upload a file that is in a different server
      assert_raise MatchError, fn -> do_transfer.(other_file, {:download, gateway, endpoint}) end
      assert_raise MatchError, fn -> do_transfer.(other_file, {:upload, gateway, endpoint}) end
    end
  end
end
