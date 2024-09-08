defmodule Core.Event.Definition do
  @moduledoc """
  "Definition" module so events can `use Core.Event.Definition`.

  Must not have compilation dependencies, otherwise it will create `compile-connected` (transitive)
  compilation dependencies.
  """

  defmacro __using__(_) do
    quote do
      alias Core.Event

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
    end
  end
end
