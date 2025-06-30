defmodule Game.Endpoint.Installation.UninstallTest do
  use Test.WebCase, async: true
  alias Game.{Installation}

  setup [:with_game_db, :with_game_webserver]

  describe "Installation.Uninstall request" do
    test "successfully starts a InstallationUninstallProcess", %{
      shard_id: shard_id,
      jwt: jwt,
      player: player
    } do
      %{server: server, nip: nip} = Setup.server_full(entity_id: player.id)
      %{installation: installation} = Setup.file(server.id, visible_by: player.id, installed?: true)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(nip, installation, player.id), %{}, shard_id: shard_id, token: jwt)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == server.id
      assert registry.tgt_installation_id == installation.id

      assert [process] = U.get_all_processes(server.id)
      assert process.type == :installation_uninstall
      assert process.data.installation_id == installation.id
      assert process.registry.tgt_installation_id == installation.id
    end

    test "returns an error if attempting to uninstall someone else's installation", %{
      jwt: jwt,
      player: player
    } do
      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # The installation exists in the remote server
      %{installation: installation} =
        Setup.file(endpoint.id, visible_by: player.id, installed?: true)

      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(endp_nip, installation, player.id), %{}, token: jwt)

      assert reason == "server_not_belongs"
    end

    # This one is a mouthful
    test "returns an error if attempting to uninstall an already uninstalled installation", %{
      jwt: jwt,
      player: player
    } do
      %{server: server, nip: nip} = Setup.server_full(entity_id: player.id)
      %{installation: installation} = Setup.file(server.id, visible_by: player.id, installed?: true)
      DB.commit()

      # Let's uninstall the installation manually, before the request starts
      Core.with_context(:server, server.id, :write, fn ->
        Svc.Installation.uninstall(installation)
      end)

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, installation, player.id), %{}, token: jwt)

      assert reason == "installation_not_found"
    end
  end

  defp build_path(%NIP{} = nip, %Installation{id: id, server_id: server_id}, player_id) do
    installation_eid = U.to_eid(id, player_id, server_id)
    "/server/#{NIP.to_external(nip)}/installation/#{installation_eid}/uninstall"
  end
end
