defmodule Webserver.Belt.ReadBody do
  alias Webserver.Vaqueiro

  # Won't parse JSONs larger than 2 MB
  @max_body_size 2_000_000

  def call(customs_request, conveyor, _opts) do
    request = customs_request.cowboy_request

    # TODO: This will require some fine-tunning when accepting file uploads

    cond do
      # TODO: Do not use `:cowboy_req.parse_header/2`. If the header is invalid, it breaks
      # silently
      {"application", "json", []} !=
          :cowboy_req.parse_header("content-type", request) ->
        Conveyor.halt_with_response(customs_request, conveyor, 415)

      request.body_length > @max_body_size ->
        Conveyor.halt_with_response(customs_request, conveyor, 413)

      true ->
        # TODO: Replace original `cowboy_request` with `new_cowboy_request`
        {:ok, raw_body, _new_cowboy_request} = Vaqueiro.read_req_body(request)

        cond do
          raw_body == "" ->
            %{customs_request | unsafe_params: %{}}

          true ->
            try do
              %{customs_request | unsafe_params: :json.decode(raw_body)}
            rescue
              ErlangError ->
                Conveyor.halt_with_response(customs_request, conveyor, 400)
            end
        end
    end
  end
end
