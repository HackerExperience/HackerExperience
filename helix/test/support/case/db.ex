defmodule Test.DBCase do
  use ExUnit.CaseTemplate
  alias Feeb.DB

  using do
    quote do
      import ExUnit.CaptureLog
      import Test.Setup.Shared
      # import Test.Assertions
      # import Test.Finders
      # import Test.Utils

      alias HELL.{Random, Utils}
      alias Test.Setup
      alias Test.Utils, as: U
      alias Feeb.DB
    end
  end

  setup tags do
    if Map.get(tags, :init_db, true) do
      do_setup(tags)
    else
      {:ok, %{}}
    end
  end

  def do_setup(tags) do
    # TODO: Skip setup on tests with `unit: true` tags
    context = Map.get(tags, :db, default_db_context(tags))

    Process.put(:helix_universe, context)

    {_, {:ok, shard_id, path}} = :timer.tc(fn -> Test.DB.Setup.new_test_db(context) end)

    {:ok, %{db: path, shard_id: shard_id, db_context: context}}
  end

  defp default_db_context(%{file: file}) do
    cond do
      file =~ "/test/lobby" -> :lobby
      file =~ "/test/game" -> Enum.random([:singleplayer, :multiplayer])
      :else -> raise "TODO db context at Test.DBCase"
    end
  end
end
