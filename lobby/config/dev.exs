import Config

config :dblite,
  data_dir: "/he2",
  migrations_dir: "priv/migrations",
  contexts: %{
    lobby: %{
      shard_type: :global
    }
  }
