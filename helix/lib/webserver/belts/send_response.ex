defmodule Webserver.Belt.SendResponse do
  use Webserver.Conveyor.Belt

  def call(%{xargs: %{sse: true}, cowboy_request: cowboy_request} = request, conveyor, _) do
    case conveyor.response_status do
      # If the SSE endpoint returned 200, then all is good and we can establish the SSE connection
      200 ->
        # Set required headers for a SSE connection
        cowboy_request = set_sse_headers(cowboy_request)

        # Start streaming
        cowboy_request = :cowboy_req.stream_reply(200, cowboy_request)

        # TODO: Merge this state with custom state returned from the Sync endpoint
        sse_state = %{dispatcher: :sse}

        %{request | cowboy_request: cowboy_request, cowboy_return: {:start_sse, sse_state}}

      e when e >= 400 ->
        # In the event of an error, we immediatelly return the error code
        cowboy_request = push_conveyor_response(cowboy_request, conveyor)
        %{request | cowboy_request: cowboy_request, cowboy_return: :ok}
    end
  end

  def call(%{cowboy_request: cowboy_request} = request, conveyor, _) do
    cowboy_request = push_conveyor_response(cowboy_request, conveyor)
    %{request | cowboy_request: cowboy_request, cowboy_return: :ok}
  end

  defp push_conveyor_response(cowboy_request, conveyor) do
    body = JSON.encode!(conveyor.response_message)
    :cowboy_req.reply(conveyor.response_status, %{}, body, cowboy_request)
  end

  defp set_sse_headers(req) do
    req = :cowboy_req.set_resp_header("content-type", "text/event-stream", req)
    req = :cowboy_req.set_resp_header("connection", "keep-alive", req)
    :cowboy_req.set_resp_header("cache-control", "no-cache", req)
  end
end
