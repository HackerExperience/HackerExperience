defmodule Test.Setup do
  alias __MODULE__, as: S

  defmacro __using__(_) do
    quote do
      alias Keyword, as: Kw
      alias Test.Setup, as: S
      alias DBLite, as: DB
      alias HELL.{Random, Utils}
    end
  end

  # Lobby
  defdelegate lobby_user(opts \\ []), to: S.Lobby.User, as: :new
end
