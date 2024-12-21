defmodule Core.Event.Loggable.Definition do
  @moduledoc """
  "Definition" module so events can `use Core.Event.Loggable.Definition`.

  Must not have compilation dependencies, otherwise it will create `compile-connected` (transitive)
  compilation dependencies.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Core.Event.Loggable.Behaviour
    end
  end
end
