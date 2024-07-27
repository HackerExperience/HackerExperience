import Config

config :helix, :db, data_dir: "/helix_data"

config :dblite,
  data_dir: "/he2",
  migrations_dir: "priv/migrations",
  contexts: %{
    lobby: %{
      shard_type: :global
    }
  }
