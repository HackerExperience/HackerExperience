defmodule Game.Endpoint.File.DeleteTest do
  use Test.WebCase, async: true
  alias Game.{File}

  setup [:with_game_db, :with_game_webserver]

  describe "File.Delete request" do
    test "successfully starts a FileDeleteProcess (gateway)", %{jwt: jwt, player: player} do
      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      file = Setup.file!(gateway.id, visible_by: player.id)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(nip, file, player.id), %{}, token: jwt)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.tgt_file_id == file.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_delete
      assert process.data.file_id == file.id
      assert process.registry.tgt_file_id == file.id
    end

    test "successfully starts a FileDeleteProcess (endpoint)", %{jwt: jwt, player: player} do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # This File exists in the Endpoint and is visible by the Player (Gateway Owner)
      file = Setup.file!(endpoint.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id)}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == endpoint.id
      assert registry.tgt_file_id == file.id

      # No processes on Gateway (of course) and we just created one process in the Endpoint
      assert [] = U.get_all_processes(gateway.id)
      assert [process] = U.get_all_processes(endpoint.id)
      assert process.type == :file_delete
      assert process.data.file_id == file.id
      assert process.registry.tgt_file_id == file.id
    end

    test "fails to delete a File remotely if a valid Tunnel is not provided", %{
      jwt: jwt,
      player: player
    } do
      # Gateway and Endpoint are real servers, but there is no endpoint between them
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()

      # This File exists in the Endpoint and is visible by the Player (Gateway Owner)
      file = Setup.file!(endpoint.id, visible_by: player.id)
      Core.commit()

      # Empty params, meaning no Tunnel was provided
      params = %{}

      assert {:error, %{status: 400, error: %{msg: "nip_not_found"}}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)

      # What if we provide a Tunnel that exists, that targets this endpoint but belongs to somebody
      # else? That's just... mean. Note this is not really possible, because `player` would not have
      # access to the external ID generated to the other player, but let's test this anyways
      Core.begin_context(:universe, :write)
      %{nip: other_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: other_nip, target_nip: endp_nip)
      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id)}
      Core.commit()

      # Okay we still get an error
      assert {:error, %{status: 400, error: %{msg: "nip_not_found"}}} =
               post(build_path(endp_nip, file, player.id), params, token: jwt)

      # And of course, if we pass in a valid Tunnel, everything works as expected
      Core.begin_context(:universe, :write)
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)
      params = %{tunnel_id: tunnel.id |> ID.to_external(player.id, gateway.id)}
      Core.commit()

      assert {:ok, %{status: 200}} = post(build_path(endp_nip, file, player.id), params, token: jwt)
    end

    test "fails to delete a File if lacking Visibility", %{jwt: jwt, player: player} do
      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      # The file exists in the Gateway but it isn't visible by the player
      file = Setup.file!(gateway.id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: "file_not_found"}}} =
               post(build_path(nip, file, player.id), %{}, token: jwt)
    end

    test "returns an error if file is in another server", %{jwt: jwt, player: player} do
      %{nip: nip} = Setup.server_full(entity_id: player.id)
      # The file exists, but in a different server
      file = Setup.file!(Setup.server!().id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, file, player.id), %{}, token: jwt)

      assert reason == "file_not_found"
    end
  end

  defp build_path(%NIP{} = nip, %File{} = file, player_id) do
    file_eid = ID.to_external(file.id, player_id, file.server_id)
    "/server/#{NIP.to_external(nip)}/file/#{file_eid}/delete"
  end
end
