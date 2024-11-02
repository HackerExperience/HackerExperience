defmodule Test.Setup do
  alias __MODULE__, as: S

  # Game
  defdelegate entity(opts \\ []), to: S.Entity, as: :new
  defdelegate entity!(opts \\ []), to: S.Entity, as: :new!
  defdelegate entity_lite(opts \\ []), to: S.Entity, as: :new_lite
  defdelegate entity_lite!(opts \\ []), to: S.Entity, as: :new_lite!
  defdelegate log(server_id, opts \\ []), to: S.Log, as: :new
  defdelegate log!(server_id, opts \\ []), to: S.Log, as: :new!
  defdelegate log_visibility(player_id, opts \\ []), to: S.Log, as: :new_visibility
  defdelegate log_visibility!(player_id, opts \\ []), to: S.Log, as: :new_visibility!
  defdelegate player(opts \\ []), to: S.Player, as: :new
  defdelegate player!(opts \\ []), to: S.Player, as: :new!
  defdelegate player_lite(opts \\ []), to: S.Player, as: :new_lite
  defdelegate player_lite!(opts \\ []), to: S.Player, as: :new_lite!
  defdelegate server(opts \\ []), to: S.Server, as: :new
  defdelegate server!(opts \\ []), to: S.Server, as: :new!
  defdelegate server_lite(opts \\ []), to: S.Server, as: :new_lite
  defdelegate server_lite!(opts \\ []), to: S.Server, as: :new_lite!

  # Lobby
  defdelegate lobby_user(opts \\ []), to: S.Lobby.User, as: :new
end
