defmodule Test.Utils do
  alias __MODULE__, as: U

  defmacro __using__(_) do
    quote do
      alias Keyword, as: Kw
      alias Test.Setup, as: S
      alias Test.Utils, as: U
      alias Feeb.DB
      alias HELL.{Random, Utils}
    end
  end

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
end
