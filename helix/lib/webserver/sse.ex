defmodule Webserver.SSE do
  def info({:send_event, event}, req, state) do
    data = "data: #{event}\n\n"
    :ok = :cowboy_req.stream_body(data, :nofin, req)
    # TODO: Check if hibernating the SSE process is something worth doing
    # This depends heavily on how often we send healthchecks/pings
    {:ok, req, state, :hibernate}
  end

  def terminate(reason, _req, _state) do
    IO.puts("Terminating! #{inspect(reason)}")
    :ok
  end
end