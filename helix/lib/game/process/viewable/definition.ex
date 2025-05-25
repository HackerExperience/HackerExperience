defmodule Game.Process.Viewable.Definition do
  defmacro __using__(_) do
    quote do
      @behaviour Game.Process.Viewable.Behaviour

      use Norm
      import Core.Spec

      alias Core.ID
      alias Game.Process
    end
  end
end
