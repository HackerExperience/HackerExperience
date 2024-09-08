import Config

config :feebdb,
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
    },
    sp_player: %{
      shard_type: :dedicated,
      domains: [:player]
    },
    mp_player: %{
      shard_type: :dedicated,
      domains: [:player]
    },
    sp_server: %{
      shard_type: :dedicated,
      domains: [:server]
    },
    mp_server: %{
      shard_type: :dedicated,
      domains: [:server]
    }
  }
