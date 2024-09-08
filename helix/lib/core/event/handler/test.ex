defmodule Core.Event.Handler.Test do
  @behaviour Core.Event.Handler.Behaviour

  require Logger

  @table :processed_events

  def on_event(%ev_mod{}, %{relay: nil}) do
    Logger.warning("No relay set for event #{ev_mod}")
    :ok
  end

  def on_event(%ev_mod{} = data, ev) do
    key = {ev.id, ev.relay.request_id, ev.relay.x_request_id}
    :ets.insert(@table, {key, %{event: ev, mod: ev_mod, data: data}})
    :ok
  end
end
