defmodule Lobby.Webserver.Hooks do
  @behaviour Webserver.Hooks

  alias DBLite, as: DB

  @impl true
  def on_get_params_ok(req, _) do
    DBLite.begin(:lobby, req.session.shard_id, :write)
    {:ok, req}
  end

  @impl true
  def on_handle_request_ok(req, _) do
    DB.commit()
    {:ok, req}
  end

  # TODO: Hook on "before_push" that asserts there's no pending DB transaction or whatever
end
