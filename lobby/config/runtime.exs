import Config

config :webserver,
  routes: Lobby.Webserver.routes(),
  belts: Lobby.Webserver.belts()
