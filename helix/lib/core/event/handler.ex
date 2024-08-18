defmodule Core.Event.Handler do
  defmacro __using__(_) do
    quote do
      @behaviour Core.Event.Handler.Behaviour
    end
  end
end
