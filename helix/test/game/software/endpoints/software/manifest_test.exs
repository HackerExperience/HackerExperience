defmodule Game.Endpoint.Software.ManifestTest do
  use Test.WebCase, async: true

  setup [:with_game_db, :with_game_webserver]

  describe "Software.Manifest request" do
    test "returns the manifest (unauthenticated)" do
      assert {:ok, %{status: 200, data: %{manifest: manifest}}} = get(build_path(), %{})

      # Manifest contains expected data. Let's use `cracker` as example
      assert cracker = Enum.find(manifest, fn software -> software["type"] == "cracker" end)
      assert cracker["type"] == "cracker"
      assert cracker["extension"] == "crc"
    end

    test "returns the manifest (authenticated)", %{shard_id: shard_id, jwt: jwt} do
      assert {:ok, %{status: 200, data: %{manifest: _}}} =
               get(build_path(), %{}, shard_id: shard_id, token: jwt)
    end
  end

  defp build_path,
    do: "/software/manifest"
end
