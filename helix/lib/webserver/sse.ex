defmodule Webserver.SSE do
  def send_message(pid, payload) do
    send(pid, {:push_event, payload})
  end

  def ping(req, state) do
    ping_msg = ":\n\n"
    do_send_message!(ping_msg, req, state)
  end

  def info({:push_event, event}, req, state) do
    data = "data: #{event}\n\n"
    do_send_message!(data, req, state)
  end

  def terminate(reason, _req, _state) do
    IO.puts("Terminating! #{inspect(reason)}")
    :ok
  end

  defp do_send_message!(payload, req, state) do
    :ok = :cowboy_req.stream_body(payload, :nofin, req)
    # TODO: Check if hibernating the SSE process is something worth doing
    # This depends heavily on how often we send healthchecks/pings
    {:ok, req, state, :hibernate}
  end
end
