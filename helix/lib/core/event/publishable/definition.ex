defmodule Core.Event.Publishable.Definition do
  @moduledoc """
  "Definition" module so events can `use Core.Event.Publishable.Definition`.

  Must not have compilation dependencies, otherwise it will create `compile-connected` (transitive)
  compilation dependencies.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Core.Event.Publishable.Behaviour
      use Norm
    end
  end
end
