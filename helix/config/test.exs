import Config

config :logger, level: :warning

config :feebdb,
  data_dir: "/he2_test",
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
  },
  is_test_mode: true
