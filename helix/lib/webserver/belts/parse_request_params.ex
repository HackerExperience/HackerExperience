defmodule Webserver.Belt.ParseRequestParams do
  def call(request, _conveyor, _opts) do
    cowboy_request = request.cowboy_request

    qs_params =
      cowboy_request
      |> :cowboy_req.parse_qs()
      |> Map.new()

    # bindings =
    #   request.bindings
    #   |> MapUtils.stringify_keys()
    #   |> MapUtils.cast_integers()

    # TODO: Only merge body if request is not multipart/upload

    new_raw_params =
      qs_params
      |> Map.merge(cowboy_request.bindings)
      |> Map.merge(request.raw_params)

    Map.put(request, :raw_params, new_raw_params)
  end
end
