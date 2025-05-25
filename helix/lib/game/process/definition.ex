defmodule Game.Process.Definition do
  defmacro __using__(_) do
    quote do
      # TODO: Make it a behaviour at some point
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    process = env.module
    resourceable = get_resourceable_mod(process)
    _executable = get_executable_mod(process)
    _viewable = get_viewable_mod(process)

    quote do
      if not Module.defines?(__MODULE__, {:on_db_load, 1}) do
        def on_db_load(data), do: data
      end

      if not Module.defines?(__MODULE__, {:get_name, 0}) do
        def get_name do
          [_, _ | rest] = Module.split(__MODULE__)

          rest
          |> Enum.join("_")
          |> String.downcase()
        end
      end

      def resources(params) do
        Game.Process.Resourceable.get_resources(unquote(resourceable), params)
      end
    end
  end

  defp get_resourceable_mod(process),
    do: get_mod(process, Resourceable)

  def get_executable_mod(process),
    do: get_mod(process, Executable)

  def get_viewable_mod(process),
    do: get_mod(process, Viewable)

  def get_mod(process, implementation) do
    mod = Module.concat(process, implementation)

    try do
      mod.__info__(:functions)
    rescue
      UndefinedFunctionError ->
        raise "Process #{inspect(process)} is missing the #{mod} implementation"
    end

    mod
  end
end
