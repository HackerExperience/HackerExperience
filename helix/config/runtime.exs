import Config

config :helix, Lobby.Webserver, port: if(Mix.env() != :test, do: 4000, else: 5000)

config :helix, :webserver, webservers: [Lobby.Webserver]
