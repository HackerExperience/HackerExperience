defmodule Game.Process.Viewable.Definition do
  defmacro __using__(_) do
    quote do
      alias Core.ID
      alias Game.Process
    end
  end
end
