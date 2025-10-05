defmodule Test.Setup do
  alias __MODULE__, as: S

  # Key entrypoints
  defdelegate entity(opts \\ []), to: S.Entity, as: :new
  defdelegate entity!(opts \\ []), to: S.Entity, as: :new!
  defdelegate entity_lite(opts \\ []), to: S.Entity, as: :new_lite
  defdelegate entity_lite!(opts \\ []), to: S.Entity, as: :new_lite!
  defdelegate player(opts \\ []), to: S.Player, as: :new
  defdelegate player!(opts \\ []), to: S.Player, as: :new!
  defdelegate player_lite(opts \\ []), to: S.Player, as: :new_lite
  defdelegate player_lite!(opts \\ []), to: S.Player, as: :new_lite!
  defdelegate server(opts \\ []), to: S.Server, as: :new
  defdelegate server!(opts \\ []), to: S.Server, as: :new!
  defdelegate server_full(opts \\ []), to: S.Server, as: :new_full
  defdelegate server_full!(opts \\ []), to: S.Server, as: :new_full!
  defdelegate server_lite(opts \\ []), to: S.Server, as: :new_lite
  defdelegate server_lite!(opts \\ []), to: S.Server, as: :new_lite!

  # Game
  defdelegate network_connection(server_id, opts \\ []), to: S.NetworkConnection, as: :new
  defdelegate network_connection!(server_id, opts \\ []), to: S.NetworkConnection, as: :new!
  defdelegate process(server_id, opts \\ []), to: S.Process, as: :new
  defdelegate process!(server_id, opts \\ []), to: S.Process, as: :new!
  defdelegate process_spec(server_id, entity_id, opts \\ []), to: S.Process, as: :spec
  defdelegate tunnel(opts \\ []), to: S.Tunnel, as: :new
  defdelegate tunnel!(opts \\ []), to: S.Tunnel, as: :new!
  defdelegate tunnel_lite(opts \\ []), to: S.Tunnel, as: :new_lite
  defdelegate tunnel_lite!(opts \\ []), to: S.Tunnel, as: :new_lite!

  # Server
  defdelegate file(server_id, opts \\ []), to: S.File, as: :new
  defdelegate file!(server_id, opts \\ []), to: S.File, as: :new!
  defdelegate log(server_id, opts \\ []), to: S.Log, as: :new
  defdelegate log!(server_id, opts \\ []), to: S.Log, as: :new!

  # Scanner
  defdelegate scanner_instance(opts \\ []), to: S.Scanner, as: :new_instance
  defdelegate scanner_instance!(opts \\ []), to: S.Scanner, as: :new_instance!
  defdelegate scanner_instances(opts \\ []), to: S.Scanner, as: :new_instances
  defdelegate scanner_instances!(opts \\ []), to: S.Scanner, as: :new_instances!

  # Player
  defdelegate file_visibility(player_id, opts \\ []), to: S.File, as: :new_visibility
  defdelegate file_visibility!(player_id, opts \\ []), to: S.File, as: :new_visibility!
  defdelegate log_visibility(player_id, opts \\ []), to: S.Log, as: :new_visibility
  defdelegate log_visibility!(player_id, opts \\ []), to: S.Log, as: :new_visibility!

  # Lobby
  defdelegate lobby_user(opts \\ []), to: S.Lobby.User, as: :new
end
