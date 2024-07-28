import Config

config :logger, level: :warning

config :dblite,
  data_dir: "/he2_test",
  migrations_dir: "priv/migrations",
  contexts: %{
    lobby: %{
      shard_type: :global
    }
  },
  is_test_mode: true
