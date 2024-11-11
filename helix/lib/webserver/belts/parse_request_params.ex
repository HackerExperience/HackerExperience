defmodule Webserver.Belt.ParseRequestParams do
  use Webserver.Conveyor.Belt

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

    # In order to remain consistent, all of `raw_params` keys should be a string
    normalized_cowboy_bindings = Renatils.Map.stringify_keys(cowboy_request.bindings)

    new_raw_params =
      qs_params
      |> Map.merge(normalized_cowboy_bindings)
      |> Map.merge(request.raw_params)

    Map.put(request, :raw_params, new_raw_params)
  end
end
