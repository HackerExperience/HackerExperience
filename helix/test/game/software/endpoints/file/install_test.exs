defmodule Game.Endpoint.File.InstallTest do
  use Test.WebCase, async: true
  alias Game.{File}

  setup [:with_game_db, :with_game_webserver]

  describe "File.Install request" do
    test "successfully starts a FileInstallProcess", %{shard_id: shard_id} do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      file = Setup.file!(gateway.id)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(gtw_nip, file.id), %{}, shard_id: shard_id, token: jwt)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id.id == data.process_id
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :file_install
      assert process.data.file_id == file.id

      # TODO: Assert / add support for source|target_file_id
    end

    @tag :skip
    test "returns an error if file is in another server"

    @tag :skip
    test "returns an error if file is lacking visibility"

    @tag :skip
    test "returns an error if there already is an equivalent installation"
  end

  defp build_path(%NIP{} = nip, %File.ID{} = file_id),
    do: "/server/#{NIP.to_external(nip)}/file/#{ID.to_external(file_id)}/install"
end
