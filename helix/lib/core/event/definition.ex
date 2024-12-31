defmodule Core.Event.Definition do
  @moduledoc """
  "Definition" module so events can `use Core.Event.Definition`.

  Must not have compilation dependencies, otherwise it will create `compile-connected` (transitive)
  compilation dependencies.
  """

  defmacro __using__(_) do
    quote do
      alias Core.Event
      alias Game.Handlers

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @name || raise "You must specify the event name via @name"

      @doc """
      Returns the event name.
      """
      def get_name, do: @name

      if not Module.defines?(__MODULE__, {:get_handlers, 2}) do
        @doc """
        This module does not have any custom handlers.
        """
        def handlers(_, _), do: []
      end
    end
  end
end
