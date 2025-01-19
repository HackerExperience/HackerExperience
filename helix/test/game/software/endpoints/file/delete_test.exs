defmodule Game.Endpoint.File.DeleteTest do
  use Test.WebCase, async: true
  alias Game.{File}

  setup [:with_game_db, :with_game_webserver]

  describe "File.Delete request" do
    test "successfully starts a FileDeleteProcess (gateway)" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      file = Setup.file!(gateway.id, visible_by: player.id)
      DB.commit()

      assert {:ok, %{status: 200, data: _data}} =
               post(build_path(nip, file.id), %{}, token: jwt)

      # TODO: Assert the process is created
    end
  end

  defp build_path(%NIP{} = nip, %File.ID{} = file_id),
    do: "/server/#{NIP.to_external(nip)}/file/#{ID.to_external(file_id)}/delete"
end
