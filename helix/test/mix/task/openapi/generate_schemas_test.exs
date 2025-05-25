defmodule Mix.Tasks.Openapi.GenerateSchemasTest do
  use ExUnit.Case, async: true
  alias Mix.Tasks.Openapi.GenerateSchemas

  @tmp_dir "./tmp/test_data/openapi_schemas"

  setup do
    File.mkdir_p(@tmp_dir)

    on_exit(fn ->
      true = String.starts_with?(@tmp_dir, "./tmp")
      File.rm_rf(@tmp_dir)
    end)

    {:ok, %{}}
  end

  describe "run/1" do
    test "successfully generates json and yaml specs" do
      GenerateSchemas.run(["--target-dir", @tmp_dir])

      # Both JSON and YAML files were created for the GameAPI, LobbyAPI, EventsAPI and ProcessesAPI
      assert [
               "events.json",
               "events.yaml",
               "game.json",
               "game.yaml",
               "lobby.json",
               "lobby.yaml",
               "processes.json",
               "processes.yaml"
             ] ==
               @tmp_dir |> File.ls!() |> Enum.sort()

      # JSON file is decodeable and appears to be correct for all APIs
      assert_spec("lobby.json", "Lobby API")
      assert_spec("game.json", "Game API")
      assert_spec("events.json", "Events API")
      assert_spec("processes.json", "Processes API")
    end
  end

  defp assert_spec(path, title) do
    spec =
      @tmp_dir
      |> Path.join(path)
      |> File.read!()
      |> :json.decode()

    assert Map.has_key?(spec, "components")
    assert Map.has_key?(spec, "info")
    assert Map.has_key?(spec, "openapi")
    assert Map.has_key?(spec, "paths")
    assert spec["info"]["title"] == title
  end
end
