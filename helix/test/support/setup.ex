defmodule Test.Setup do
  alias __MODULE__, as: S

  defmacro __using__(_) do
    quote do
      alias Keyword, as: Kw
      alias Test.Setup, as: S
      alias Feeb.DB
      alias HELL.{Random, Utils}
      alias Game.Services, as: Svc
    end
  end

  # Game
  defdelegate entity(opts \\ []), to: S.Entity, as: :new
  defdelegate entity!(opts \\ []), to: S.Entity, as: :new!
  defdelegate player(opts \\ []), to: S.Player, as: :new
  defdelegate player!(opts \\ []), to: S.Player, as: :new!
  defdelegate server(opts \\ []), to: S.Server, as: :new
  defdelegate server!(opts \\ []), to: S.Server, as: :new!

  # Lobby
  defdelegate lobby_user(opts \\ []), to: S.Lobby.User, as: :new
end
