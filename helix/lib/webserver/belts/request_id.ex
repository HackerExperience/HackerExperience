defmodule Webserver.Belt.RequestId do
  use Webserver.Conveyor.Belt

  # TODO: Consider scenario where frontend specifies a request ID (x-request-id)
  def call(request, _, _) do
    request_id = gen_request_id()
    %{request | id: request_id}
  end

  defp gen_request_id do
    # TODO: Figure out what to use as request ID
    System.monotonic_time()
    |> to_string()
  end
end
