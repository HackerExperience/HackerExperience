defmodule Game.Endpoint.File.TransferTest do
  use Test.WebCase, async: true

  alias Game.File

  setup [:with_game_db, :with_game_webserver]

  describe "File.Transfer request" do
    test "successfully starts a FileTransferProcess (download)", %{jwt: jwt, player: player} do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Endpoint and is visible by the Player (Gateway Owner)
      file = Setup.file!(endpoint.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :download}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)

      # A FileTransferProcess(transfer_type=download) was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.src_file_id == file.id
      assert registry.src_tunnel_id == tunnel.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_transfer
      assert process.data.transfer_type == :download
      assert process.data.endpoint_id == endpoint.id
    end

    test "successfully starts a FileTransferProcess (upload)", %{jwt: jwt, player: player} do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Gateway and is visible by the Player (Gateway Owner)
      file = Setup.file!(gateway.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :upload}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)

      # A FileTransferProcess(transfer_type=upload) was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.src_file_id == file.id
      assert registry.src_tunnel_id == tunnel.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_transfer
      assert process.data.transfer_type == :upload
      assert process.data.endpoint_id == endpoint.id
    end

    test "returns an error if player does not have visibility over file", %{
      jwt: jwt,
      player: player
    } do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Endpoint but it is not visible by the player
      file = Setup.file!(endpoint.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :download}

      assert {:error, %{status: 400, error: %{msg: "file_not_found"}}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)
    end

    test "returns an error if file does not exist", %{jwt: jwt, player: player} do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists somewhere else and is visible by the player
      other_file = Setup.file!(Setup.server!().id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :download}

      assert {:error, %{status: 400, error: %{msg: "file_not_found"}}} =
               post(build_path(endp_nip, other_file, player.id), params, token: jwt)
    end

    test "returns an error if player is attempting to download his own file", %{
      jwt: jwt,
      player: player
    } do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This file exists in the players own gateway
      file = Setup.file!(gateway.id, visible_by: player.id)

      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :download}

      # Fails at an earlier stage because the Tunnel does not have Gateway as target
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(gtw_nip, file, player.id), params, token: jwt)
    end

    test "returns an error if player is attempting to upload endpoint's own file", %{
      jwt: jwt,
      player: player
    } do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This file exists in the endpoint
      file = Setup.file!(endpoint.id, visible_by: player.id)

      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id), transfer_type: :upload}

      # Fails at an earlier stage because the Tunnel does not have Gateway as target
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(gtw_nip, file, player.id), params, token: jwt)
    end

    test "returns an error if player is attempting to transfer a file without a valid tunnel", %{
      jwt: jwt,
      player: player
    } do
      %{server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # There is NO Tunnel between Gateway and Endpoint; this is an unrelated tunnel
      %{nip: other_nip, entity: other_entity} = Setup.server()
      other_tunnel = Setup.tunnel!(source_nip: other_nip, target_nip: endp_nip)

      # This file exists in the players own gateway
      file_gtw = Setup.file!(gateway.id, visible_by: player.id)
      file_endp = Setup.file!(endpoint.id, visible_by: player.id)

      DB.commit()

      params_download = %{
        tunnel_id: other_tunnel.id |> U.to_eid(other_entity.id),
        transfer_type: :download
      }

      params_upload = %{
        tunnel_id: other_tunnel.id |> U.to_eid(other_entity.id),
        transfer_type: :upload
      }

      params_download_no_tunnel = %{transfer_type: :download}
      params_upload_no_tunnel = %{transfer_type: :upload}

      # Can't download file using unrelated tunnel
      assert {:error, %{status: 400, error: %{msg: "tunnel_id:id_not_found"}}} =
               post(build_path(endp_nip, file_endp, player.id), params_download, token: jwt)

      # Can't upload file using unrelated tunnel
      assert {:error, %{status: 400, error: %{msg: "tunnel_id:id_not_found"}}} =
               post(build_path(endp_nip, file_gtw, player.id), params_upload, token: jwt)

      # Can't download file without specifying a tunnel
      assert {:error, %{status: 400, error: %{msg: "invalid_input"}}} =
               post(build_path(endp_nip, file_endp, player.id), params_download_no_tunnel,
                 token: jwt
               )

      # Can't upload file without specifying a tunnel
      assert {:error, %{status: 400, error: %{msg: "invalid_input"}}} =
               post(build_path(endp_nip, file_gtw, player.id), params_upload_no_tunnel, token: jwt)
    end
  end

  defp build_path(%NIP{} = nip, %File{} = file, player_id) do
    file_eid = ID.to_external(file.id, player_id, file.server_id)
    "/server/#{NIP.to_external(nip)}/file/#{file_eid}/transfer"
  end
end
