defmodule Core.Event.Publishable.Spec do
  def spec do
    %{
      type: :events,
      title: "Events API",
      version: "1.0.0",
      endpoints: events()
    }
  end

  defp events do
    # Make sure all Helix modules are loaded
    Helix.Application.wait_until_helix_modules_are_loaded()

    # Iterate over every Elixir.Game module and find the ones who implement the Publishable
    # behaviour. Then, return their corresponding event module.
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

      Core.Event.Publishable.Behaviour in mod_behaviours
    end)
    |> Enum.map(fn publishable_mod ->
      publishable_mod
      |> Module.split()
      |> List.delete_at(-1)
      |> Module.concat()
    end)
  end
end
