defmodule Test.DBCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ExUnit.CaptureLog
      import Test.Setup.Shared
      import Test.Assertions
      import Core.Spec, only: [validate_spec: 2]

      alias Renatils.Random
      alias Test.Setup
      alias Test.Random, as: R
      alias Test.Utils, as: U
      alias Feeb.DB

      # Common Core/Game aliases
      alias Core.ID
      alias Core.NIP
      alias Game.Services, as: Svc
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
    {_, {:ok, shard_id, path}} = :timer.tc(fn -> Test.DB.Setup.new_test_db(context) end)

    Process.put(:helix_universe, context)
    Process.put(:helix_universe_shard_id, shard_id)

    {:ok, %{db: path, shard_id: shard_id, db_context: context}}
  end

  defp default_db_context(%{file: file}) do
    cond do
      file =~ "/test/lobby" -> :lobby
      true -> Enum.random([:singleplayer, :multiplayer])
    end
  end
end
