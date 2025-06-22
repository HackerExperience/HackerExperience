defmodule Game.Endpoint.Software.ManifestTest do
  use Test.WebCase, async: true
  alias Game.{Software}

  setup [:with_game_webserver, :with_game_db]

  describe "Software.Manifest request" do
    test "returns the manifest (unauthenticated)" do
      assert {:ok, %{status: 200, data: %{manifest: manifest}}} = get(build_path(), %{})

      # Manifest contains expected data. Let's use `cracker` as example
      assert cracker = Enum.find(manifest, fn software -> software["type"] == "cracker" end)
      assert cracker["type"] == "cracker"
      assert cracker["extension"] == "crc"
    end

    test "returns the manifest (authenticated)", %{shard_id: shard_id} do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      assert {:ok, %{status: 200, data: %{manifest: _}}} =
               get(build_path(), %{}, shard_id: shard_id, token: jwt)
    end
  end

  defp build_path,
    do: "/software/manifest"
end
