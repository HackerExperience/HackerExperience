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

      # Both json and yaml files were created
      assert ["lobby.json", "lobby.yaml"] ==
               @tmp_dir |> File.ls!() |> Enum.sort()

      # JSON file is decodeable and appears to be semantically correct
      spec =
        @tmp_dir
        |> Path.join("lobby.json")
        |> File.read!()
        |> :json.decode()

      assert Map.has_key?(spec, "components")
      assert Map.has_key?(spec, "info")
      assert Map.has_key?(spec, "openapi")
      assert Map.has_key?(spec, "paths")
      assert spec["info"]["title"] == "Lobby API"
    end
  end
end
