defmodule Test.DB do
  alias Feeb.DB
  alias Feeb.DB.{Config}

  def on_start do
    # Don't have the Feeb.DB boot running in parallel to what we are doing here
    Feeb.DB.Boot.wait_boot!()

    delete_all_dbs()
    File.mkdir_p!(props_path())
    File.mkdir_p!(test_dbs_path())

    Enum.each(Config.contexts(), fn context ->
      File.mkdir_p!("#{test_dbs_path()}/#{context.name}")
    end)

    Test.DB.Prop.ensure_props_are_created()
  end

  def on_finish do
    delete_all_dbs()
  end

  # @doc """
  # Given the following shard_id, make sure it is migrated
  # """
  # def ensure_migrated(context, shard_id) do
  #   path = Repo.get_path(context, shard_id)

  #   # The repo will automatically set up and migrate (if needed)
  #   {:ok, pid} = Repo.start_link({context, shard_id, path, :readwrite})

  #   # We need to close it in order to synchronously finish the migration
  #   GenServer.call(pid, {:close})
  # end

  def props_path, do: "#{Config.data_dir()}/db_props"
  def test_dbs_path, do: "#{Config.data_dir()}"

  @doc """
  Inserts a dummy entry into `schema` which will force it to have a random-like autoincrement.
  Particularly useful when creating Players and Servers, which have their own dedicated-but-global
  shard. Usually, if your test will create Player or Server shards, you most likely want to use this
  function.
  """
  def random_autoincrement(schema) do
    table = schema.__table__()
    rand = :rand.uniform() |> Kernel.*(1_000_000_000) |> trunc()
    DB.raw!("insert into #{table} (id) values (#{rand})")
    # NOTE: One would feel compeled to delete the newly inserted entry. However, deleting it will
    # cause SQLite to fallback the autoincrement counter to 1, defeating the purpose of the function
  end

  @doc """
  Assumes the caller wants a random autoincrement on both Entity and Server. This function is
  automatically imported on every test case (via `Test.Setup.Shared`).
  """
  def with_random_autoincrement do
    random_autoincrement(Game.Entity)
    # random_autoincrement(Game.Server)
  end

  defp delete_all_dbs do
    path = test_dbs_path()
    false = String.contains?(path, "*")
    false = String.contains?(path, " ")

    "#{path}/**/*.{db,db-shm,db-wal}"
    |> Path.wildcard()
    |> Stream.each(fn path ->
      File.rm(path)
    end)
    |> Stream.run()
  end
end
