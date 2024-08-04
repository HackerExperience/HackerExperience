defmodule Test.Web do
  alias Webserver.Request

  def gen_cowboy_req(opts \\ []) do
    Test.Web.Request.gen_cowboy_req(opts)
  end

  def gen_req(endpoint \\ nil, opts \\ []) do
    cowboy_req = gen_cowboy_req(Keyword.get(opts, :cowboy_opts, []))

    Request.new(cowboy_req, endpoint, :scope_todo)
    |> Map.put(:parsed, Keyword.get(opts, :parsed, nil))
    |> Map.put(:params, Keyword.get(opts, :params, nil))
    |> Map.put(:context, Keyword.get(opts, :context, nil))
    |> Map.put(:result, Keyword.get(opts, :result, nil))
    |> Map.put(:response, Keyword.get(opts, :response, nil))
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
      headers: gen_cowboy_req_headers(opts[:headers] || []),
      method: Keyword.get(opts, :method, "POST"),
      host_info: :undefined,
      path_info: :undefined,
      streamid: 1,
      body_length: Keyword.get(opts, :body_length, 9381),
      has_body: Keyword.get(opts, :has_body, true),
      qs: Keyword.get(opts, :qs, ""),
      sock: {{127, 0, 0, 1}, Keyword.get(opts, :port, 4001)}
    }
  end

  defp gen_cowboy_req_headers(opts) do
    default_headers =
      %{
        "accept" => "*/*",
        "content-length" => 9381,
        "content-type" => "application/json",
        "host" => "localhost:4001",
        "user-agent" => "curl/8.2.1"
      }

    Map.merge(default_headers, Keyword.get(opts, :headers, %{}))
  end
end
