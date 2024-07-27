import Config

config :helix, :webserver,
  routes: Lobby.Webserver.routes(),
  # TODO: Support Belts being applied on a per-route basis
  belts: Lobby.Webserver.belts()
