defmodule DB.BootTest do
  use Test.DBCase, async: true
  alias DB.SQLite
  alias DB.{Boot, Migrator}

  @moduletag db: :raw

  setup %{db: db} do
    {:ok, conn} = SQLite.open(db)
    SQLite.raw!(conn, "PRAGMA synchronous=0")
    {:ok, %{conn: conn}}
  end

  describe "boot" do
    @tag unit: true
    test "stores migrations in persistent term" do
      # For the test environment, it includes both test and real migrations
      assert [:lobby, :test] = Migrator.get_all_migrations() |> Map.keys() |> Enum.sort()
    end

    @tag unit: true
    test "stores latest versions in persistent term" do
      all_migrations = Migrator.get_all_migrations()

      lobby_latest = Migrator.get_latest_version(:lobby)
      # Test migrations rarely change and thus can be hard-coded here
      test_latest = 2

      assert lobby_latest ==
               Migrator.calculate_latest_version(:lobby, all_migrations)

      assert test_latest ==
               Migrator.calculate_latest_version(:test, all_migrations)
    end
  end

  describe "validate_database/2" do
    @tag db: :player
    @tag skip: true
    test "crashes if the model does not match the code", %{shard_id: shard_id} do
      all_models = Boot.get_all_models()

      DB.begin(:player, shard_id, :write)

      # Let's insert a column in imoveis (`mob` domain)
      {:ok, _} = DB.raw("ALTER TABLE servers ADD COLUMN foo TEXT;")

      e =
        assert_raise RuntimeError, fn ->
          Boot.validate_database(all_models, :player)
        end

      assert e.message =~ "fields do not match: [:foo]"

      DB.rollback()

      # With the changed rolled back, it works as expected
      DB.begin(:player, shard_id, :read)
      Boot.validate_database(all_models, :player)
      DB.commit()

      # Now we'll insert a column in `users` (`core` domain)
      DB.begin(:player, shard_id, :write)
      {:ok, _} = DB.raw("ALTER TABLE servers ADD COLUMN foo TEXT;")

      e =
        assert_raise RuntimeError, fn ->
          Boot.validate_database(all_models, :player)
        end

      assert e.message =~ "fields do not match: [:foo]"

      DB.rollback()
    end
  end
end
