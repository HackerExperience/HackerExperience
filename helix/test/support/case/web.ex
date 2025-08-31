defmodule Test.WebCase do
  use ExUnit.CaseTemplate

  # TODO: Maybe have a Test.WebLobbyCase dedicated to Lobby?

  using do
    quote do
      import ExUnit.CaptureLog
      import Test.HTTPClient
      import Test.Setup.Shared
      import Test.Web
      import Test.Assertions

      alias Feeb.DB
      alias Renatils.Random

      alias Test.Setup
      alias Test.Random, as: R
      alias Test.Utils, as: U

      # Common Core/Game aliases
      alias Core.ID
      alias Core.NIP
      alias Game.Services, as: Svc
    end
  end

  setup tags do
    {:ok, %{shard_id: shard_id} = db_ctx} = Test.DBCase.do_setup(tags)

    ctx = %{session: Test.Web.gen_session(shard_id: shard_id)}
    {:ok, Map.merge(db_ctx, ctx)}
  end
end
