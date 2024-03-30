import Config

config :helix, :db,
  data_dir: "/tmp/helix/test_dbs",
  migrations_dir: "priv/test/migrations"

config :logger, level: :warning
