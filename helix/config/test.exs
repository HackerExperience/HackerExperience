import Config

config :logger, level: :warning

config :feebdb,
  data_dir: System.get_env("HELIX_TEST_DATA_DIR", "/he2_test"),
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
    },
    player: %{
      shard_type: :dedicated
    },
    server: %{
      shard_type: :dedicated
    }
  },
  is_test_mode: true
