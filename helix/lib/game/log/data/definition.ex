defmodule Game.Log.Data.Definition do
  defmacro __using__(_) do
    quote do
      use Norm
      import Core.Spec

      @behaviour Game.Log.Data.Behaviour
    end
  end
end
