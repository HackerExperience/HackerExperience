import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# TODO: This config should be applied depending on the node purpose (flag)
# Unless we add a per-route hook config, which is not trivial and could affect
# performance. But something needs to be done here
# Alternatively, what if I start two webservers? Seems feasible and a better option...
# We would then have something like:
# config :helix, Lobby.Webserver, as well as:
# config :helix, webservers: [Lobby.Webserver, Game.Multiplayer.Webserver] etc
config :helix, :webserver, hooks: Lobby.Webserver.Hooks

# Parei aqui: fazer o webserve funcionar com a config atual, e entao
# refatorar pra ter 2 webservers (esse refactor pode ser depois)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
