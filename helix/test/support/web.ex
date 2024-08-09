defmodule Test.Web do
  alias Webserver.Request

  def gen_cowboy_req(opts \\ []) do
    Test.Web.Request.gen_cowboy_req(opts)
  end

  def gen_req(endpoint \\ nil, opts \\ []) do
    cowboy_req = gen_cowboy_req(Keyword.get(opts, :cowboy_opts, []))
    webserver = Keyword.get(opts, :webserver, Game.Webserver.Multiplayer)

    Request.new(cowboy_req, endpoint, webserver)
    |> Map.put(:parsed, Keyword.get(opts, :parsed, nil))
    |> Map.put(:params, Keyword.get(opts, :params, nil))
    |> Map.put(:context, Keyword.get(opts, :context, nil))
    |> Map.put(:result, Keyword.get(opts, :result, nil))
    |> Map.put(:response, Keyword.get(opts, :response, nil))
    |> Map.put(:universe, Keyword.get(opts, :universe, nil))
  end

  def gen_session(opts \\ []) do
    %{
      shard_id: Keyword.get(opts, :shard_id, 999_999)
    }
  end
end

defmodule Test.Web.Request do
  def gen_cowboy_req(opts \\ []) do
    %{
      pid: Keyword.get(opts, :pid, self()),
      port: Keyword.get(opts, :port, 4001),
      scheme: Keyword.get(opts, :scheme, "http"),
      version: Keyword.get(opts, :version, :"HTTP/1.1"),
      path: Keyword.get(opts, :path, "/api/v1/test_endpoint"),
      host: Keyword.get(opts, :host, "localhost"),
      peer: {{127, 0, 0, 1}, 60426},
      bindings: Keyword.get(opts, :bindings, %{}),
      ref: :server,
      cert: :undefined,
      headers: gen_cowboy_req_headers(opts),
      method: Keyword.get(opts, :method, "POST"),
      host_info: :undefined,
      path_info: :undefined,
      streamid: 1,
      body_length: Keyword.get(opts, :body_length, 9381),
      has_body: Keyword.get(opts, :has_body, false),
      qs: Keyword.get(opts, :qs, ""),
      sock: {{127, 0, 0, 1}, Keyword.get(opts, :port, 4001)}
    }
  end

  defp gen_cowboy_req_headers(opts) do
    maybe_put_mock_header = fn headers ->
      case opts[:mock_body] do
        nil ->
          headers

        mock_body when is_binary(mock_body) ->
          Map.put(headers, "test-body-mock", mock_body)

        mock_body when is_map(mock_body) ->
          stringified_body = mock_body |> :json.encode() |> to_string()
          Map.put(headers, "test-body-mock", stringified_body)
      end
    end

    default_headers =
      %{
        "accept" => "*/*",
        "content-length" => 9381,
        "content-type" => "application/json",
        "host" => "localhost:4001",
        "user-agent" => "curl/8.2.1",
        "test-lobby-shard-id" => "1"
      }

    Map.merge(default_headers, Keyword.get(opts, :headers, %{}))
    |> maybe_put_mock_header.()
  end
end
