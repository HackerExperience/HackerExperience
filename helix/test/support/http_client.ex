defmodule Test.HTTPClient do
  import Req.Request, only: [put_header: 3]
  alias HELL.Utils

  # TODO
  @default_base_url "http://localhost:4001/v1"

  def post(endpoint_or_url, body \\ %{}, opts \\ [])

  def post(partial_url, body, opts) do
    [
      url: get_full_url(partial_url),
      body: body |> :json.encode() |> to_string(),
      method: :post
    ]
    |> Req.new()
    |> add_default_headers()
    |> maybe_add_lobby_context(partial_url, opts)
    # |> maybe_add_events_header(opts)
    |> Req.Request.run_request()
    |> parse_response()
  end

  defp add_default_headers(req) do
    req
    |> put_header("accept", "application/json")
    |> put_header("content-type", "application/json")
  end

  defp maybe_add_lobby_context(req, partial_url, opts) do
    if is_lobby_request(partial_url) do
      shard_id = Keyword.fetch!(opts, :shard_id)
      put_header(req, "test-lobby-shard-id", "#{shard_id}")
    else
      req
    end
  end

  # defp maybe_add_events_header(req, opts) do
  #   if Keyword.get(opts, :events, false),
  #     do: put_header(req, "test-emit-events", "1"),
  #     else: req
  # end

  defp parse_response({_, %Req.Response{status: status, body: ""}}),
    do: %{status: status, raw_body: "", body: nil, data: nil, error: nil} |> wrap_response(status)

  defp parse_response({_, %Req.Response{status: status, body: body}}) when is_binary(body) do
    body = body |> :json.decode() |> Utils.Map.atomify_keys()

    %{
      status: status,
      raw_body: body,
      body: body,
      data: body[:data],
      error: body[:error]
    }
    |> wrap_response(status)
  end

  defp wrap_response(response, status) when status >= 200 and status <= 399,
    do: {:ok, response}

  defp wrap_response(response, status) when status >= 400,
    do: {:error, response}

  defp get_full_url(url) do
    if String.starts_with?(url, "/") do
      "#{get_base_url()}#{url}"
    else
      url
    end
  end

  defp get_base_url do
    Process.get(:test_http_client_base_url, @default_base_url)
  end

  defp is_lobby_request(partial_url) do
    case partial_url do
      "/user/register" -> true
      "/user/login" -> true
      _ -> false
    end
  end
end
