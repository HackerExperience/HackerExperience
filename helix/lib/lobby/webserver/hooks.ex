defmodule Lobby.Webserver.Hooks do
  @behaviour Webserver.Hooks

  alias Feeb.DB

  @impl true
  def on_get_params_ok(req, _) do
    Process.put(:helix_universe, :lobby)
    Feeb.DB.begin(:lobby, req.session.shard_id, :write)
    {:ok, req}
  end

  @impl true
  def on_handle_request_ok(req, _) do
    DB.commit()
    {:ok, req}
  end

  # TODO: Hook on "before_push" that asserts there's no pending DB transaction or whatever
end
