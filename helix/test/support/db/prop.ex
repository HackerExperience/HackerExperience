defmodule Test.DB.Prop do
  alias DBLite.{Config, SQLite}
  alias __MODULE__

  # NOTE: If instead of :nooping you decide on always generating props for each
  # test execution, watch out for flakes. Run the test suite dozens of times in
  # a row and make sure everything passes consistently.
  def ensure_props_are_created do
    Config.contexts()
    |> Enum.each(fn context ->
      context.name
      |> get_path()
      |> File.stat()
      |> case do
        # {:ok, _} -> :noop
        {:ok, _} -> create(context)
        {:error, :enoent} -> create(context)
      end
    end)
  end

  def create(context) do
    {t, _} = :timer.tc(fn -> do_create(context) end)
    IO.puts("Generated #{context.name}.db prop in #{trunc(t / 1000)} ms")
  end

  # defp do_create(%{name: :raw}) do
  #   prop_path = get_path(:raw)
  #   # This is the definition of `raw` -- nothing in it
  #   File.rm(prop_path)
  #   File.touch!(prop_path)
  # end

  defp do_create(%{name: ctx_name}) do
    prop_path = get_path(ctx_name)

    # TODO: Is this rm really necessary? We already delete everything  on test startup
    File.rm(prop_path)

    # Create them (in data dir)
    DBLite.begin(ctx_name, 0, :write)
    DBLite.commit()

    # Make sure the DB in datadir is synced
    db_path = DBLite.Repo.get_path(ctx_name, 0)
    {:ok, db_conn} = SQLite.open(db_path)
    :ok = SQLite.exec(db_conn, "PRAGMA wal_checkpoint(TRUNCATE)")
    SQLite.close(db_conn)

    # Copy it into the prop dir
    :ok = File.cp(db_path, prop_path)

    # # Add test data in the prop database
    # {:ok, prop_conn} = SQLite.open(prop_path)
    # "PRAGMA synchronous=OFF" |> SQLite.raw2!(prop_conn)
    # Prop.Data.generate!(ctx_name, prop_conn)
    # "PRAGMA wal_checkpoint(TRUNCATE)" |> SQLite.raw2!(prop_conn)
  end

  def get_path(ctx_name), do: "#{Test.DB.props_path()}/#{ctx_name}"
end