defmodule Game.Process.Viewable.Spec do
  def spec do
    %{
      type: :processes,
      title: "Processes API",
      version: "1.0.0",
      endpoints: processes()
    }
  end

  defp processes do
    # Make sure all Helix modules are loaded
    Helix.Application.wait_until_helix_modules_are_loaded()

    # Iterate over every Elixir.Game module and find the ones who implement the Viewable
    # module. Then, return their corresponding event module.
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

      Game.Process.Viewable.Behaviour in mod_behaviours
    end)
    |> Enum.map(fn viewable_mod ->
      viewable_mod
      |> Module.split()
      |> List.delete_at(-1)
      |> Module.concat()
    end)
  end
end
