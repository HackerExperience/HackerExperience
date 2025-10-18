defmodule Core.Webserver.Belt.SetEventRelay do
  alias Core.Event

  def call(request, _, _) do
    :request
    |> Event.Relay.new(%{request_id: request.id, x_request_id: request.x_request_id})
    |> Event.Relay.set_env()

    request
  end
end
