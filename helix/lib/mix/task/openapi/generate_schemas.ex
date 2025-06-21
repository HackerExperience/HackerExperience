defmodule Mix.Tasks.Openapi.GenerateSchemas do
  use Mix.Task
  require Logger

  alias Webserver.OpenApi.Spec.Generator, as: SpecGenerator

  @default_target_dir "priv/openapi"

  @doc """
  Generates the OpenAPI schemas for Lobby.

  Usage:
  > mix openapi.generate_schemas [--target-dir priv/openapi]
  """
  @impl Mix.Task
  def run(raw_args) do
    {args, _} = OptionParser.parse!(raw_args, strict: [target_dir: :string])

    case :timer.tc(fn -> do_run(args) end) do
      {t, :ok} ->
        Logger.info("OpenAPI specs written in #{trunc(t / 1000)}ms")

      {_, reason} ->
        Logger.error("Failed to generate specs: #{inspect(reason)}")
        exit(:error)
    end
  end

  defp do_run(args) do
    target_dir = get_target_dir(args)
    setup_env(target_dir)

    generate_openapi_spec_file(:lobby, target_dir)
    generate_openapi_spec_file(:game, target_dir)
    generate_openapi_spec_file(:events, target_dir)
    generate_openapi_spec_file(:processes, target_dir)
    generate_openapi_spec_file(:logs, target_dir)
  end

  defp setup_env(target_dir) do
    # We need every Helix module loaded so we can dynamically find events
    Helix.Application.eagerly_load_helix_modules()

    File.mkdir_p!(target_dir)
  end

  defp generate_openapi_spec_file(:lobby, target_dir) do
    Lobby.Webserver.spec()
    |> SpecGenerator.generate()
    |> write_spec(:lobby, target_dir)
  end

  defp generate_openapi_spec_file(:game, target_dir) do
    Game.Webserver.spec()
    |> SpecGenerator.generate()
    |> write_spec(:game, target_dir)
  end

  defp generate_openapi_spec_file(:events, target_dir) do
    Core.Event.Publishable.Spec.spec()
    |> SpecGenerator.generate()
    |> write_spec(:events, target_dir)
  end

  defp generate_openapi_spec_file(:processes, target_dir) do
    Game.Process.Viewable.Spec.spec()
    |> SpecGenerator.generate()
    |> write_spec(:processes, target_dir)
  end

  defp generate_openapi_spec_file(:logs, target_dir) do
    Game.Log.Data.Spec.spec()
    |> SpecGenerator.generate()
    |> write_spec(:logs, target_dir)
  end

  defp write_spec(spec, name, target_dir) do
    path = Path.join(target_dir, "#{name}.json")
    File.write!("#{path}.tmp", JSON.encode!(spec))
    sort_json_file!(path)
  end

  defp sort_json_file!(path) do
    with {_, 1} <- System.cmd("which", ["jq"]),
         do: raise("You need `jq` installed in your system")

    # Sort the JSON object. We have to walk over it because arrays are not sorted by default
    jq_cmd = "jq -S 'walk(if type == \"array\" then sort else . end)'"

    case System.shell("cat #{path}.tmp | #{jq_cmd} > #{path} && rm #{path}.tmp") do
      {_, 0} -> :ok
      {error, _} -> {:error, error}
    end
  end

  defp get_target_dir(args),
    do: Keyword.get(args, :target_dir, @default_target_dir)
end
