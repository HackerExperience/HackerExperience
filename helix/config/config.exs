import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# TODO: This config should be applied depending on the node purpose (flag)
# Unless we add a per-route hook config, which is not trivial and could affect
# performance. But something needs to be done here
config :webserver,
  hooks: Lobby.Webserver.Hooks

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
