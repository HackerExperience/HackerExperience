defmodule Game.Endpoint.File.TransferTest do
  use Test.WebCase, async: true

  alias Game.File

  setup [:with_game_db, :with_game_webserver]

  describe "File.Transfer request" do
    test "successfully starts a FileTransferProcess (download)" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Endpoint and is visible by the Player (Gateway Owner)
      file = Setup.file!(endpoint.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :download}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, file.id), params, token: jwt)

      # A FileTransferProcess(transfer_type=download) was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id.id == data.process_id
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.src_file_id == file.id
      assert registry.src_tunnel_id == tunnel.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_transfer
      assert process.data.transfer_type == :download
      assert process.data.endpoint_id == endpoint.id
    end

    test "successfully starts a FileTransferProcess (upload)" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Gateway and is visible by the Player (Gateway Owner)
      file = Setup.file!(gateway.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :upload}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, file.id), params, token: jwt)

      # A FileTransferProcess(transfer_type=upload) was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id.id == data.process_id
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.src_file_id == file.id
      assert registry.src_tunnel_id == tunnel.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_transfer
      assert process.data.transfer_type == :upload
      assert process.data.endpoint_id == endpoint.id
    end

    test "returns an error if player does not have visibility over file" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Endpoint but it is not visible by the player
      file = Setup.file!(endpoint.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :download}

      assert {:error, %{status: 400, error: %{msg: "file_not_found"}}} =
               post(build_path(endp_nip, file.id), params, token: jwt)
    end

    test "returns an error if file does not exist" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists somewhere else and is visible by the player
      other_file = Setup.file!(Setup.server!().id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :download}

      assert {:error, %{status: 400, error: %{msg: "file_not_found"}}} =
               post(build_path(endp_nip, other_file.id), params, token: jwt)
    end

    test "returns an error if player is attempting to download his own file" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This file exists in the players own gateway
      file = Setup.file!(gateway.id, visible_by: player.id)

      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :download}

      # Fails at an earlier stage because the Tunnel does not have Gateway as target
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(gtw_nip, file.id), params, token: jwt)
    end

    test "returns an error if player is attempting to upload endpoint's own file" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This file exists in the endpoint
      file = Setup.file!(endpoint.id, visible_by: player.id)

      DB.commit()

      params = %{tunnel_id: tunnel.id |> ID.to_external(), transfer_type: :upload}

      # Fails at an earlier stage because the Tunnel does not have Gateway as target
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(gtw_nip, file.id), params, token: jwt)
    end

    test "returns an error if player is attempting to transfer a file without a valid tunnel" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # There is NO Tunnel between Gateway and Endpoint; this is an unrelated tunnel
      %{nip: other_nip} = Setup.server()
      other_tunnel = Setup.tunnel!(source_nip: other_nip, target_nip: endp_nip)

      # This file exists in the players own gateway
      file_gtw = Setup.file!(gateway.id, visible_by: player.id)
      file_endp = Setup.file!(endpoint.id, visible_by: player.id)

      DB.commit()

      params_download = %{tunnel_id: other_tunnel.id |> ID.to_external(), transfer_type: :download}
      params_upload = %{tunnel_id: other_tunnel.id |> ID.to_external(), transfer_type: :upload}
      params_download_no_tunnel = %{tunnel_id: nil, transfer_type: :download}
      params_upload_no_tunnel = %{tunnel_id: nil, transfer_type: :upload}

      # Can't download file using unrelated tunnel
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(endp_nip, file_endp.id), params_download, token: jwt)

      # Can't upload file using unrelated tunnel
      assert {:error, %{status: 400, error: %{msg: "tunnel_not_found"}}} =
               post(build_path(endp_nip, file_gtw.id), params_upload, token: jwt)

      # Can't download file without specifying a tunnel
      assert {:error, %{status: 400, error: %{msg: "invalid_input"}}} =
               post(build_path(endp_nip, file_endp.id), params_download_no_tunnel, token: jwt)

      # Can't upload file without specifying a tunnel
      assert {:error, %{status: 400, error: %{msg: "invalid_input"}}} =
               post(build_path(endp_nip, file_gtw.id), params_upload_no_tunnel, token: jwt)
    end
  end

  defp build_path(%NIP{} = nip, %File.ID{} = file_id),
    do: "/server/#{NIP.to_external(nip)}/file/#{ID.to_external(file_id)}/transfer"
end
