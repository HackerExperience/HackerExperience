defmodule Game.Webserver.Hooks do
  @behaviour Webserver.Hooks

  alias Feeb.DB
  alias Game.Endpoint

  @impl true
  def on_get_params_ok(req, {endpoint, _path, _method}) do
    true = req.universe in [:singleplayer, :multiplayer]

    Process.put(:helix_universe, req.universe)
    Process.put(:helix_universe_shard_id, req.session.shard_id)

    # NOTE: I believe that for the vast majority of requests, :read is a better default than :write.
    # Furthermore, when I do need to write, it will often be via processes, in which case the TOP
    # is responsible for handling the connection lifecycle.
    connection_type = if endpoint == Endpoint.Player.Sync, do: :write, else: :read
    Feeb.DB.begin(req.universe, req.session.shard_id, connection_type)

    {:ok, req}
  end

  @impl true
  def on_handle_request_ok(req, _) do
    DB.commit()
    {:ok, req}
  end
end
