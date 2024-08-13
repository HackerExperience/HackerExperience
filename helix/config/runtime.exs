import Config

config :helix, Lobby.Webserver, port: if(Mix.env() != :test, do: 4000, else: 5000)

config :helix, Game.Webserver.Singleplayer,
  port: if(Mix.env() != :test, do: 4001, else: 5001),
  hooks_module: Game.Webserver.Hooks

config :helix, Game.Webserver.Multiplayer,
  port: if(Mix.env() != :test, do: 4002, else: 5002),
  hooks_module: Game.Webserver.Hooks

config :helix, :webserver,
  webservers: [Game.Webserver.Singleplayer, Game.Webserver.Multiplayer, Lobby.Webserver]
