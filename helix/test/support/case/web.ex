defmodule Test.WebCase do
  use ExUnit.CaseTemplate

  # TODO: Maybe have a Test.WebLobbyCase dedicated to Lobby?

  using do
    quote do
      import ExUnit.CaptureLog
      import Test.HTTPClient
      import Test.Setup.Shared
      import Test.Web

      alias DBLite, as: DB
      alias HELL.{Random, Utils}
      alias Test.Setup
      alias Test.Utils, as: U

      alias Game.Services, as: Svc
    end
  end

  setup tags do
    {:ok, %{shard_id: shard_id} = db_ctx} = Test.DBCase.do_setup(tags)

    ctx = %{session: Test.Web.gen_session(shard_id: shard_id)}
    {:ok, Map.merge(db_ctx, ctx)}
  end
end
