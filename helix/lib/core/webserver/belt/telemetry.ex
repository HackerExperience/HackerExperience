defmodule Core.Webserver.Belt.Telemetry do
  def call(%{cowboy_request: cowboy_request} = request, x, _) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:webserver, :request, :start],
      %{system_time: System.system_time(:nanosecond)},
      %{request: request}
    )

    before_send = fn req ->
      duration = System.monotonic_time() - start_time
      :telemetry.execute([:webserver, :request, :stop], %{duration: duration}, %{request: req})
      request
    end

    # TODO: Have an API to append `before_send` hooks
    %{request | before_send: before_send}
  end
end
