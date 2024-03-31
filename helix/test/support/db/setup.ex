defmodule Test.DB.Setup do
  alias Test.DB.Prop
  alias DB.SQLite

  def test_conn(path) do
    {:ok, conn} = SQLite.open(path)
    "PRAGMA synchronous=OFF" |> SQLite.raw2!(conn)
    "PRAGMA journal_mode=memory" |> SQLite.raw2!(conn)
    conn
  end

  def new_test_db(db, opts \\ []) do
    prop_path = Prop.get_path(db)
    shard_id = Keyword.get(opts, :shard_id, gen_shard_id())

    context =
      cond do
        db == :lobby -> :lobby
        db == :player -> :player
        true -> :test
      end

    test_db_path = "#{Test.DB.test_dbs_path()}/#{context}/#{shard_id}.db"

    File.cp!(prop_path, test_db_path)
    {:ok, shard_id, test_db_path}
  end

  def compile_test_queries do
    domains = [:friends, :users, :posts]

    try_and_compile = fn domain ->
      try do
        DB.Query.fetch_all!({:test, domain})
      rescue
        _ ->
          DB.Query.compile(
            "priv/test/queries/test/#{domain}.sql",
            {:test, domain}
          )
      end
    end

    Enum.each(domains, fn domain -> try_and_compile.(domain) end)
  end

  defp gen_shard_id do
    :rand.uniform() |> Kernel.*(1_000_000) |> trunc()
  end
end

defmodule Test.DB.Prop do
  alias DB.SQLite
  alias __MODULE__

  @props [:raw, :simple, :player, :lobby]

  # NOTE: If instead of :nooping you decide on always generating props for each
  # test execution, watch out for flakes. Run the test suite dozens of times in
  # a row and make sure everything passes consistently.
  def ensure_props_are_created do
    @props
    |> Enum.each(fn prop_id ->
      prop_id
      |> get_path()
      |> File.stat()
      |> case do
        {:ok, _} -> :noop
        {:error, :enoent} -> create(prop_id)
      end
    end)
  end

  def create(db) do
    {t, _} = :timer.tc(fn -> do_create(db, get_path(db)) end)
    IO.puts("Generated #{db}.db prop in #{trunc(t / 1000)} ms")
  end

  defp do_create(db, path) do
    File.rm(path)
    {:ok, c} = SQLite.open(path)

    "PRAGMA synchronous=OFF" |> SQLite.raw2!(c)
    Prop.Data.generate!(db, c)
  end

  def get_path(:raw), do: "#{Test.DB.props_path()}/raw.db"
  def get_path(:simple), do: "#{Test.DB.props_path()}/simple.db"
  def get_path(:player), do: "#{Test.DB.props_path()}/player.db"
  def get_path(:lobby), do: "#{Test.DB.props_path()}/lobby.db"
end

defmodule Test.DB.Prop.Data do
  def generate!(db, c) do
    Process.put(:conn, c)
    do_generate(db)
  end

  defp do_generate(:raw) do
    # This is why it's "raw"
    :noop
  end

  defp do_generate(:player) do
    :noop
    # "priv/schemas/player.sql"
    # |> queries_from_dump_file()
    # |> Enum.each(&run/1)
  end

  defp do_generate(:lobby) do
    "priv/schemas/lobby.sql"
    |> queries_from_dump_file()
    |> Enum.each(&run/1)
  end

  defp do_generate(:simple) do
    friends_data()
    posts_data()

    # TODO: Ideally, simple should also run Migrator.setup_metadata_table
    # (or ingest its SQL directly0)
  end

  defp posts_data do
    """
    CREATE TABLE posts (
      id INTEGER PRIMARY KEY,
      title TEXT,
      body TEXT,
      inserted_at TEXT,
      updated_at TEXT
    )
    """
    |> run()
  end

  defp friends_data do
    """
    CREATE TABLE friends (
      id INTEGER PRIMARY KEY,
      name TEXT
    )
    """
    |> run()

    [
      {1, "Phoebe"},
      {2, "Joey"},
      {3, "Chandler"},
      {4, "Monica"},
      {5, "Ross"},
      {6, "Rachel"}
    ]
    |> Enum.each(fn {id, name} ->
      "INSERT INTO friends (id, name) VALUES (#{id}, '#{name}')"
      |> run()
    end)
  end

  defp run(sql) do
    c = Process.get(:conn)
    DB.SQLite.raw!(c, sql)
  end

  defp queries_from_dump_file(path) do
    path
    |> File.read!()
    |> String.split(";")
    |> Enum.map(fn sql -> sql |> String.replace("\n", "") end)
    |> Enum.reject(fn sql -> sql == "" or String.starts_with?(sql, "--") end)
    |> Enum.map(fn sql -> "#{sql};" end)
  end
end
