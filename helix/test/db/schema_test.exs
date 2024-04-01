defmodule DB.SchemaTest do
  use Test.DBCase, async: true

  alias Sample.{Friend}

  @context :test

  describe "sandbox" do
    @tag skip: true
    test "select", %{shard_id: shard_id} do
      DB.begin(@context, shard_id, :read)

      assert %Friend{id: 1, name: "Phoebe", __meta__: meta} = DB.one({:friends, :get_by_id}, [1])

      assert meta.origin == :db
    end

    @tag skip: true
    test "insert with query definition", %{shard_id: shard_id} do
      DB.begin(@context, shard_id, :write)

      friend = Friend.new(%{id: 7, name: "Mike"})

      IO.puts("Inserting:")
      IO.inspect(friend)

      # Caminho app -> DB
      DB.insert({:friends, :insert}, friend)
      |> IO.inspect()

      friend = Friend.new(%{id: 8, name: "Ursula"})
      DB.insert(friend)

      # Caminho DB -> app
      # :persistent_term.get()
      # |> IO.inspect()
    end
  end
end
