defmodule Mix.Tasks.Helix.GenerateOpenapiSchemas do
  use Mix.Task
  require Logger

  alias Webserver.OpenApi.Spec.Generator, as: SpecGenerator

  @target_dir "priv/openapi"

  @impl Mix.Task
  def run(_args) do
    case :timer.tc(&do_run/0) do
      {t, :ok} ->
        Logger.info("OpenAPI specs written in #{trunc(t / 1000)}ms")

      {_, reason} ->
        Logger.error("Failed to generate specs: #{inspect(reason)}")
    end
  end

  defp do_run do
    setup_env()
    generate_openapi_spec_file(:lobby)
  end

  defp setup_env do
    File.mkdir_p!(@target_dir)
  end

  defp generate_openapi_spec_file(:lobby) do
    Lobby.Webserver.spec()
    |> SpecGenerator.generate()
    |> write_spec(:lobby)
  end

  defp write_spec(spec, name) do
    path = Path.join(@target_dir, "#{name}.json")
    File.write!(path, :json.encode(spec))
    generate_yaml_version(path)
  end

  defp generate_yaml_version(json_path) do
    with {_, 1} <- System.cmd("which", ["yq"]),
         do: raise("You need `yq` installed in your system")

    yaml_path = String.replace(json_path, ".json", ".yaml")

    case System.shell("cat #{json_path} | yq -y > #{yaml_path}") do
      {_, 0} -> :ok
      {error, _} -> {:error, error}
    end
  end
end
