defmodule DB.MigratorTest do
  use Test.DBCase, async: true
  alias DB.SQLite
  alias DB.Migrator
  # TODO: Move metadata tests to its own module

  @moduletag db: :raw

  setup %{db: db} do
    {:ok, conn} = SQLite.open(db)
    SQLite.raw!(conn, "PRAGMA synchronous=0")
    {:ok, %{conn: conn}}
  end

  describe "migrate/2" do
    @tag capture_log: true
    @tag skip: true
    test "migrates to latest (lobby migrations)", %{conn: conn} do
      Migrator.Metadata.setup(conn)

      latest_lobby_version = 2
      Migrator.cache_latest_version(:lobby, latest_lobby_version, :process)

      # This is a fresh DB, so we'll migrate from zero to latest
      migrations = [{:lobby, 0, latest_lobby_version}]
      assert :ok == Migrator.migrate(conn, migrations)

      # The `users` and `sessions` tables are present
      # FIXME: Once sessions are added
      refute [] == SQLite.raw!(conn, "pragma table_info(users)")
      assert [] == SQLite.raw!(conn, "pragma table_info(sessions)")

      # The migrations are stored in the internal metadata tables
      assert %{lobby: latest_lobby_version} ==
               Migrator.Metadata.summarize_migrations(conn, :lobby)
    end
  end

  describe "migrates automatically on Repo start (lobby)" do
    @tag capture_log: true
    test "lobby - with readwrite connection", %{shard_id: shard_id} do
      :ok = DB.begin(:lobby, shard_id, :write)

      # The `accounts` and `companies` tables are present!
      refute {:ok, []} == DB.raw("pragma table_info(users)")
      assert {:ok, []} == DB.raw("pragma table_info(sessions)")
    end

    @tag capture_log: true
    test "lobby - with readonly connection", %{shard_id: shard_id} do
      :ok = DB.begin(:lobby, shard_id, :read)

      # The `accounts` and `companies` tables are present!
      refute {:ok, []} == DB.raw("pragma table_info(users)")
      assert {:ok, []} == DB.raw("pragma table_info(sessions)")
    end

    @tag skip: true
    test "player", %{shard_id: shard_id} do
      :ok = DB.begin(:player, shard_id, :write)

      # The `servers` table was created
      # FIXME: This is currently passing because the table does not yet exist
      assert {:ok, []} == DB.raw("pragma table_info(servers)")

      # No tables from lobby were created
      assert {:ok, []} == DB.raw("pragma table_info(users)")
    end
  end

  describe "get_migration_status/2" do
    @tag capture_log: true
    test "returns the expected status", %{conn: conn} do
      Migrator.cache_latest_version(:lobby, 1, :process)

      # The lobby DB is at the zeroth migration and needs to be migrated
      assert {:needs_migration, [{:lobby, 0, 1}]} ==
               Migrator.get_migration_status(conn, :lobby, :readwrite)

      # Let's migrate it up to 1
      assert :ok == Migrator.migrate(conn, [{:lobby, 0, 1}])

      # We are at 1
      assert %{lobby: 1} == Migrator.Metadata.summarize_migrations(conn, :lobby)

      # And now we are fully migrated
      assert :migrated ==
               Migrator.get_migration_status(conn, :lobby, :readwrite)
    end
  end

  describe "calculate_all_migrations/0" do
    @tag unit: true
    @tag capture_log: true
    test "maps all the migrations" do
      migrations = Migrator.calculate_all_migrations()

      # Mapped all the existing domains/contexts in the migrations folder
      assert [:lobby, :test] = migrations |> Map.keys() |> Enum.sort()

      # There are multiple migrations in lobby
      # FIXME: Once sessions are added
      refute Enum.count(migrations.lobby) > 1

      # Lobby's first migration
      assert {:sql_only, "priv/migrations/lobby/0001_add_users.sql"} = migrations.lobby[1]
    end
  end

  describe "calculate_latest_version/2" do
    @tag unit: true
    @tag capture_log: true
    test "returns the last version for each domain" do
      migrations = %{
        core: %{1 => {:sql_only, "priv/migrations/core/0001_add_users.sql"}},
        lobby: %{
          1 => {:sql_only, "priv/migrations/lobby/0001_add_accounts.sql"},
          2 =>
            {:sql_and_exs,
             [
               "priv/migrations/lobby/0002_add_companies.exs",
               "priv/migrations/lobby/0002_add_companies.sql"
             ]}
        }
      }

      assert Migrator.calculate_latest_version(:core, migrations) == 1
      assert Migrator.calculate_latest_version(:lobby, migrations) == 2
    end
  end

  describe "[calculate/cache/get]_all_migrations" do
    @tag unit: true
    test "works as expected" do
      migrations_key = {:migrator, :all_migrations}
      real_migrations = DB.Migrator.calculate_all_migrations()
      mock_migrations = %{mi: :gs}

      # Before, nothing on Process KV
      refute Process.get(migrations_key)

      # We'll save the migrations
      DB.Migrator.cache_all_migrations(real_migrations, :persistent_term)
      DB.Migrator.cache_all_migrations(mock_migrations, :process)

      # The mock migrations are in the process
      assert mock_migrations == Process.get(migrations_key)

      # The real migrations are in the PT (global, shared across tests)
      assert real_migrations == :persistent_term.get(migrations_key)

      # And when calling get migrations, we get the mock migrations, since
      # they have precedence over persistent term (in tests)
      assert mock_migrations == DB.Migrator.get_all_migrations()
    end
  end

  describe "[calculate/cache/get]_latest_version" do
    @tag unit: true
    test "works as expected" do
      version_key = {:migrator, :latest_version, :lobby}
      mock_migrations = %{lobby: %{1 => {:sql_only, []}, 2 => {:sql_only, []}}}

      # Calculates the latest version correctly
      latest_version = DB.Migrator.calculate_latest_version(:lobby, mock_migrations)

      assert latest_version == 2

      # Nothing in the process
      refute Process.get(version_key)

      # Let's save them (process only, as I don't want to mess with other tests)
      DB.Migrator.cache_latest_version(:lobby, latest_version, :process)

      # It is now in the process
      assert Process.get(version_key) == 2

      # And also in the actual function
      assert DB.Migrator.get_latest_version(:lobby) == 2
    end
  end
end
