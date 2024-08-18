defmodule Game.Webserver.Hooks do
  @behaviour Webserver.Hooks

  alias Feeb.DB

  @impl true
  def on_get_params_ok(req, _) do
    true = req.universe in [:singleplayer, :multiplayer]

    Process.put(:helix_universe, req.universe)
    Feeb.DB.begin(req.universe, req.session.shard_id, :write)

    {:ok, req}
  end

  @impl true
  def on_handle_request_ok(req, _) do
    DB.commit()
    {:ok, req}
  end
end
