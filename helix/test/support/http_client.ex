defmodule Test.HTTPClient do
  import Req.Request, only: [put_header: 3]

  # TODO
  @default_base_url "http://localhost:5000/v1"

  def post(endpoint_or_url, body \\ %{}, opts \\ [])

  def post(partial_url, body, opts) do
    [body: JSON.encode!(body), method: :post]
    |> do_process_request(partial_url, opts)
  end

  def get(endpoint_or_url, params \\ %{}, opts \\ [])

  def get(partial_url, params, opts) do
    [params: params, method: :get, retry: false]
    |> do_process_request(partial_url, opts)
  end

  defp do_process_request(req_opts, partial_url, opts) do
    req_opts
    |> Keyword.merge(url: get_full_url(partial_url))
    |> Req.new()
    |> add_default_headers()
    |> add_shard_header(partial_url, opts)
    |> add_x_request_id_header(opts)
    |> add_authorization_header(opts)
    |> Req.Request.run_request()
    |> parse_response()
  end

  defp add_default_headers(req) do
    req
    |> put_header("accept", "application/json")
    |> put_header("content-type", "application/json")
  end

  defp add_shard_header(req, partial_url, opts) do
    header_name =
      if is_lobby_request(partial_url), do: "test-lobby-shard-id", else: "test-game-shard-id"

    shard_id = opts[:shard_id] || Process.get(:helix_universe_shard_id) || raise "Missing shard_id"

    put_header(req, header_name, "#{shard_id}")
  end

  defp add_authorization_header(req, opts) do
    case Keyword.get(opts, :token, nil) do
      token when is_binary(token) ->
        put_header(req, "authorization", token)

      nil ->
        req
    end
  end

  defp add_x_request_id_header(req, opts) do
    case Keyword.get(opts, :x_request_id, nil) do
      x_request_id when is_binary(x_request_id) ->
        put_header(req, "x-request-id", x_request_id)

      nil ->
        req
    end
  end

  # defp maybe_add_events_header(req, opts) do
  #   if Keyword.get(opts, :events, false),
  #     do: put_header(req, "test-emit-events", "1"),
  #     else: req
  # end

  # defp parse_response({_, %Req.Response{status: status, body: ""}}),
  #   do: %{status: status, raw_body: "", body: nil, data: nil, error: nil} |> wrap_response(status)

  defp parse_response({_, %Req.Response{status: 404, body: ""}}) do
    %{
      status: 404,
      raw_body: "",
      body: nil,
      data: nil,
      error: nil
    }
    |> wrap_response(404)
  end

  defp parse_response({_, %Req.Response{status: status, body: raw_body}}) do
    {body, data, error} =
      cond do
        is_map(raw_body) ->
          body = Renatils.Map.atomify_keys(raw_body)
          {body, body[:data], body[:error]}

        status >= 200 and status < 300 ->
          {raw_body, raw_body, nil}

        true ->
          {raw_body, nil, raw_body}
      end

    %{
      status: status,
      raw_body: raw_body,
      body: body,
      data: data,
      error: error
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
