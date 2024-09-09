defmodule Test.Setup.Definition do
  defmacro __using__(_) do
    quote do
      alias Keyword, as: Kw
      alias Test.Setup, as: S
      alias Test.Utils, as: U
      alias Feeb.DB
      alias HELL.{Random, Utils}
      alias Game.Services, as: Svc
    end
  end
end
