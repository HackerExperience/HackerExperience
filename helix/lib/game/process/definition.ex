defmodule Game.Process.Definition do
  defmacro __using__(_) do
    quote do
      # TODO: Make it a behaviour at some point
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      if not Module.defines?(__MODULE__, {:on_db_load, 1}) do
        def on_db_load(data), do: data
      end
    end
  end
end
