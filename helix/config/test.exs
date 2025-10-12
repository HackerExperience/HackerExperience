import Config

config :logger, level: :warning

config :feebdb,
  data_dir: System.get_env("HELIX_TEST_DATA_DIR", "/he2_test"),
  migrations_dir: "priv/migrations",
  is_test_mode: true
