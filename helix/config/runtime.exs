import Config

config :feebdb,
  contexts: %{
    lobby: %{
      shard_type: :global
    },
    singleplayer: %{
      shard_type: :global,
      domains: [:game]
    },
    multiplayer: %{
      shard_type: :global,
      domains: [:game]
    },
    sp_player: %{
      shard_type: :dedicated,
      domains: [:player]
    },
    mp_player: %{
      shard_type: :dedicated,
      domains: [:player]
    },
    sp_server: %{
      shard_type: :dedicated,
      domains: [:server]
    },
    mp_server: %{
      shard_type: :dedicated,
      domains: [:server]
    },
    sp_scanner: %{
      shard_type: :global,
      domains: [:scanner]
    },
    mp_scanner: %{
      shard_type: :global,
      domains: [:scanner]
    }
  }

# Determines which role this server is taking:
# - lobby: Dedicated Lobby server
# - singleplayer: Dedicated SP server
# - multiplayer: Dedicated MP server
# - all: All-in-one (for easier dev/testing but discouraged for Production usage)
role = System.get_env("HELIX_ROLE", "all") |> String.to_atom()

if role not in [:singleplayer, :multiplayer, :lobby, :all],
  do: raise("Invalid role specified: #{inspect(role)}")

config :helix,
  role: role

config :helix, Lobby.Webserver, port: if(Mix.env() != :test, do: 4000, else: 5000)

config :helix, Game.Webserver.Singleplayer,
  port: if(Mix.env() != :test, do: 4001, else: 5001),
  hooks_module: Game.Webserver.Hooks

config :helix, Game.Webserver.Multiplayer,
  port: if(Mix.env() != :test, do: 4002, else: 5002),
  hooks_module: Game.Webserver.Hooks

enabled_webservers =
  case role do
    :lobby -> [Lobby.Webserver]
    :singleplayer -> [Game.Webserver.Singleplayer]
    :multiplayer -> [Game.Webserver.Multiplayer]
    :all -> [Game.Webserver.Singleplayer, Game.Webserver.Multiplayer, Lobby.Webserver]
  end

config :helix, :webserver, webservers: enabled_webservers
