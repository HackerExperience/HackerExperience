defmodule Core.Webserver.Belt.SetEventRelay do
  alias Core.Event

  def call(request, _, _) do
    Event.Relay.set(:request, %{request_id: request.id, x_request_id: request.x_request_id})
    request
  end
end
