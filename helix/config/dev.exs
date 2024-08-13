import Config

config :dblite,
  data_dir: "/he2",
  migrations_dir: "priv/migrations",
  contexts: %{
    lobby: %{
      shard_type: :global
    },
    singleplayer: %{
      shard_type: :global,
      domains: [:game]
    },
    multiplayer: %{
      shard_type: :global,
      domains: [:game]
    }
  }
