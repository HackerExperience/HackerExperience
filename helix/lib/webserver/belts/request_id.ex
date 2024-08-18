defmodule Webserver.Belt.RequestId do
  use Webserver.Conveyor.Belt
  alias HELL.Utils

  def call(request, _, _) do
    request_id = gen_request_id()
    %{request | id: request_id, x_request_id: get_x_request_id(request.cowboy_request)}
  end

  defp gen_request_id do
    # TODO: Figure out what to use as request ID
    System.monotonic_time()
    |> to_string()
  end

  defp get_x_request_id(cowboy_request) do
    case Map.get(cowboy_request.headers, "x-request-id") do
      x_request_id when is_binary(x_request_id) ->
        if Utils.UUID.is_valid?(x_request_id) do
          x_request_id
        end

      nil ->
        nil
    end
  end
end
