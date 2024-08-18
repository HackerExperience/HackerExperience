defmodule Core.Webserver.Belt.SetEventRelay do
  alias Core.Event.Relay

  def call(request, _, _) do
    Process.put(:helix_event_relay, Relay.new(request.id, request.x_request_id))
    request
  end
end
