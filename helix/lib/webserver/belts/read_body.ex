defmodule Webserver.Belt.ReadBody do
  alias Webserver.{Conveyor, Vaqueiro}

  # Won't parse JSONs larger than 2 MB
  @max_body_size 2_000_000

  @env Mix.env()

  def call(%{cowboy_request: cowboy_request} = request, conveyor, _opts) do
    # TODO: This will require some fine-tunning when accepting file uploads

    cond do
      # TODO: Do not use `:cowboy_req.parse_header/2`. If the header is invalid, it breaks
      # silently
      {"application", "json", []} !=
          :cowboy_req.parse_header("content-type", cowboy_request) ->
        Conveyor.halt_with_response(request, conveyor, 415)

      cowboy_request.body_length > @max_body_size ->
        Conveyor.halt_with_response(request, conveyor, 413)

      true ->
        try do
          {:ok, raw_body, new_cowboy_request} = read_request_body(cowboy_request, @env)
          raw_params = if raw_body == "", do: %{}, else: :json.decode(raw_body)
          %{request | raw_params: raw_params, cowboy_request: new_cowboy_request}
        rescue
          # Invalid JSON
          ErlangError ->
            Conveyor.halt_with_response(request, conveyor, 400)
        end
    end
  end

  defp read_request_body(%{headers: %{"test-body-mock" => raw_body}} = cowboy_request, :test),
    do: {:ok, raw_body, cowboy_request}

  defp read_request_body(cowboy_request, _),
    do: Vaqueiro.read_req_body(cowboy_request)
end
