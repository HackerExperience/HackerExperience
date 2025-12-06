defmodule Core.Telemetry.Handlers.Webserver do
  alias Core.Metrics

  def handle_event(event, measurements, metadata, config) do
    # This indirection is here to assist debugging when necessary
    do_handle_event(event, measurements, metadata, config)
  end

  defp do_handle_event([:webserver, :request, :start], _, %{request: request}, _) do
    method = request.cowboy_request.method

    traceparent = request.cowboy_request.headers["traceparent"]

    span_opts =
      cond do
        is_nil(traceparent) ->
          []

        true ->
          # TODO: Properly validate traceparent
          [_, parent_trace_id, parent_span_id, _] = String.split(traceparent, "-")
          [trace_id: parent_trace_id, parent_span_id: parent_span_id]
      end

    Hotel.Tracer.start_span("#{method} #{request.endpoint_str}", span_opts)

    :ok
  end

  defp do_handle_event([:webserver, :request, :stop], %{duration: duration}, %{request: request}, _) do
    Hotel.Tracer.end_span()
    Metrics.Webserver.count_http_request(request)
  end
end
