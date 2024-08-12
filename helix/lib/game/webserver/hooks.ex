defmodule Game.Webserver.Hooks do
  @behaviour Webserver.Hooks

  alias DBLite, as: DB
  alias Game.Endpoint

  @impl true
  def on_get_params_ok(req, _) do
    true = req.universe in [:singleplayer, :multiplayer]
    DBLite.begin(req.universe, req.session.shard_id, :write)
    {:ok, req}
  end

  @impl true
  def on_handle_request_ok(req, _) do
    DB.commit()
    {:ok, req}
  end
end
