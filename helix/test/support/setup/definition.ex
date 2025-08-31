defmodule Test.Setup.Definition do
  defmacro __using__(_) do
    quote do
      alias Keyword, as: Kw

      alias Feeb.DB
      alias Renatils.Random

      alias Test.Setup, as: S
      alias Test.Utils, as: U
      alias Test.Random, as: R

      alias Game.Services, as: Svc
    end
  end
end
