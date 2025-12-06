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

config :helix, :logger, [
  {:handler, :hotel_otlp_handler, Hotel.Log.Handler, _config = %{}}
]

otel_collector_base_url = System.get_env("OTEL_COLLECTOR_BASE_URL")
otel_collector_api_key = System.get_env("OTEL_COLLECTOR_API_KEY")
otel_exporter_auth = {:header, "Authorization", otel_collector_api_key}

config :hotel, :logs,
  exporter_url: "#{otel_collector_base_url}/v1/logs",
  exporter_auth: otel_exporter_auth

config :hotel, :traces,
  exporter_url: "#{otel_collector_base_url}/v1/traces",
  exporter_auth: otel_exporter_auth

config :hotel, :metrics,
  exporter_url: "#{otel_collector_base_url}/v1/metrics",
  exporter_auth: otel_exporter_auth,
  setup: &Core.Metrics.setup/0

{otel_service_name, otel_universe} =
  case role do
    :lobby -> {"helix-lobby", nil}
    :singleplayer -> {"helix-sp", "sp"}
    :multiplayer -> {"helix-mp", "mp"}
    :all -> {"helix-all", nil}
  end

config :hotel, :resource,
  attributes: %{
    "service.name": otel_service_name,
    "service.version": Application.spec(:helix, :vsn) |> to_string,
    "game.universe": otel_universe
  }
