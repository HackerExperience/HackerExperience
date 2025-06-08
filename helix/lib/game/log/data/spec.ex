defmodule Game.Log.Data.Spec do
  def spec do
    %{
      type: :logs,
      title: "Logs API",
      version: "1.0.0",
      endpoints: logs()
    }
  end

  defp logs do
    # Make sure all Helix modules are loaded
    Helix.Application.wait_until_helix_modules_are_loaded()

    # Iterate over every Elixir.Game module and find the ones who implement the Game.Log.Data
    # behaviour.
    # This is not particularly efficient but this snippet isn't executed during game runtime.
    :code.all_loaded()
    |> Enum.filter(fn {mod, _} ->
      mod
      |> to_string()
      |> String.starts_with?("Elixir.Game")
    end)
    |> Enum.map(fn entry -> elem(entry, 0) end)
    |> Enum.filter(fn mod ->
      mod_behaviours =
        :attributes
        |> mod.module_info()
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      Game.Log.Data.Behaviour in mod_behaviours
    end)
  end
end
