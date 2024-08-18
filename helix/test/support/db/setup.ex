defmodule Test.DB.Setup do
  alias Test.DB.Prop
  alias Feeb.DB.{SQLite}

  def test_conn(path) do
    {:ok, conn} = SQLite.open(path)
    "PRAGMA synchronous=OFF" |> SQLite.raw2!(conn)
    "PRAGMA journal_mode=memory" |> SQLite.raw2!(conn)
    conn
  end

  def new_test_db(context, opts \\ []) do
    prop_path = Prop.get_path(context)
    shard_id = Keyword.get(opts, :shard_id, gen_shard_id())

    base_test_db_path = "#{Test.DB.test_dbs_path()}/#{context}"
    test_db_path = "#{base_test_db_path}/#{shard_id}.db"

    File.mkdir_p!(base_test_db_path)
    File.cp!(prop_path, test_db_path)
    {:ok, shard_id, test_db_path}
  end

  defp gen_shard_id do
    :rand.uniform() |> Kernel.*(1_000_000) |> trunc()
  end
end
