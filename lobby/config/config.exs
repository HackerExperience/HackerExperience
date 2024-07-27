import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :webserver,
  hooks: Lobby.Webserver.Hooks

import_config "#{config_env()}.exs"
