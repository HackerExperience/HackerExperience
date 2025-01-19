defmodule Game.Endpoint.File.InstallTest do
  use Test.WebCase, async: true
  alias Game.{File}

  setup [:with_game_db, :with_game_webserver]

  describe "File.Install request" do
    test "successfully starts a FileInstallProcess", %{shard_id: shard_id} do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      file = Setup.file!(gateway.id, visible_by: player.id)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(nip, file.id), %{}, shard_id: shard_id, token: jwt)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id.id == data.process_id
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.src_file_id == file.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_install
      assert process.data.file_id == file.id
      assert process.registry.src_file_id == file.id
    end

    test "returns an error if file is in another server" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: nip} = Setup.server_full(entity_id: player.id)
      # The file exists, but in a different server
      file = Setup.file!(Setup.server!().id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, file.id), %{}, token: jwt)

      assert reason == "file_not_found"
    end

    test "returns an error if player does not have visibility over file" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      # The file exists in the Gateway but it isn't visible by the player
      file = Setup.file!(gateway.id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, file.id), %{}, token: jwt)

      assert reason == "file_not_found"

      # If we suddenly start having visibility, then we can start the process (this is mostly to
      # ensure this test is *actually* testing visibility issues and not an unrelated error).
      Setup.file_visibility!(player.id, server_id: gateway.id, file_id: file.id)

      assert {:ok, %{status: 200}} = post(build_path(nip, file.id), %{}, token: jwt)
    end

    @tag :skip
    test "returns an error if there already is an equivalent installation"
  end

  defp build_path(%NIP{} = nip, %File.ID{} = file_id),
    do: "/server/#{NIP.to_external(nip)}/file/#{ID.to_external(file_id)}/install"
end
