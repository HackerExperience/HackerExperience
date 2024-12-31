defmodule Core.Webserver.Belt.SetEventRelay do
  alias Core.Event.Relay

  def call(request, _, _) do
    relay = Relay.new(:request, %{request_id: request.id, x_request_id: request.x_request_id})
    Process.put(:helix_event_relay, relay)

    request
  end
end
