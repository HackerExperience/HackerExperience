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
      import Core.Spec

      alias Core.{ID, NIP}
      alias Game.Services, as: Svc

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      if not Module.defines?(__MODULE__, {:whom_to_publish, 1}) do
        raise "Publishable module #{__MODULE__} missing :whom_to_publish/1 callback"
      end
    end
  end
end
