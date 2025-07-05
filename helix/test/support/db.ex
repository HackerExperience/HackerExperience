defmodule Test.DB do
  alias Feeb.DB
  alias Feeb.DB.{Config}
  alias Test.Setup

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
    # To avoid Processes created during the tests to reach completion after the suite has finished
    # and we are in the process of cleaning up the shards, make sure to sTOP all the TOPs.
    DynamicSupervisor.stop(Game.Process.TOP.Supervisor)

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
  Assumes the caller wants a random autoincrement on both Entity and Server. This function
  is automatically imported on every test case (via `Test.Setup.Shared`).

  Particularly useful when creating Players and Servers, which have their own dedicated-but-global
  shard. Usually, if your test will create Player or Server shards, you most likely want to use this
  function.
  """
  def with_random_autoincrement(_opts \\ []) do
    if not Process.get(:auto_increment_set, false) do
      %{entity: %{id: entity_id}, server: %{id: server_id}} = Setup.server_lite(skip_seed: true)
      rand = :rand.uniform() |> Kernel.*(1_000_000_000) |> trunc()

      DB.raw!("PRAGMA defer_foreign_keys=1")
      DB.raw!("UPDATE players SET id = '#{rand}' WHERE id = '#{entity_id}'")
      DB.raw!("UPDATE entities SET id = '#{rand}' WHERE id = '#{entity_id}'")
      DB.raw!("UPDATE servers SET id = '#{rand}', entity_id = '#{rand}' WHERE id = '#{server_id}'")

      Process.put(:auto_increment_set, true)
    end

    :ok
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
