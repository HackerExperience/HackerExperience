defmodule Core.Event.Handler.Test do
  use Core.Event.Handler

  @table :processed_events

  def on_event(%ev_mod{} = data, ev) do
    key = {ev.id, ev.relay.request_id, ev.relay.x_request_id}
    :ets.insert(@table, {key, %{event: ev, mod: ev_mod, data: data}})
    :ok
  end
end
