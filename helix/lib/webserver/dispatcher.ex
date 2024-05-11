defmodule Webserver.Dispatcher do
  require Logger

  alias Webserver.{Belt, Endpoint, Request}

  @belts [
    Belt.RequestId,
    # Belt.HandleCors,
    Belt.ReadBody,
    Belt.ParseRequestParams,
    # Belt.Session,
    __MODULE__,
    Belt.SendResponse
  ]

  def init(cowboy_request, args) do
    {duration, {_, _, request} = result} = :timer.tc(fn -> do_dispatch(cowboy_request, args) end)

    # Log in a different process because sometimes Cowboy kills the request
    # process as soon as the response is sent and we may lose logs.
    # Note this may not happen in prod, but at least in dev it happens.
    spawn(fn -> log_request(duration, request) end)

    result
  end

  @doc """
  Belt entrypoint. Actually dispatches the request to the corresponding handler.
  """
  def call(%{endpoint: endpoint} = req, _, _) do
    session = req.session
    # true = not is_nil(session)

    id1 = 2
    id2 = 3

    with {:ok, req} <- endpoint.get_params(req, req.unsafe_params, session),
         params = req.params,
         # DB.begin(session.db_context, session.shard_id, :write),
         DB.begin(:lobby, 1, :write),
         DB.commit(),
         # DB.begin(:lobby, id1, :write),
         # DB.commit(),
         DB.begin(:lobby, id2, :write),
         # DB.raw("insert into users (password) values ('abc')"),
         DB.raw("select * From users where id = 1"),
         DB.raw("select * From users where id = 2"),
         DB.raw("select * From users where id = 3"),
         DB.raw("select * From users where id = 4"),
         DB.raw("select * from users where id = 5"),
         DB.raw("select * from users where id = 6"),
         # DB.raw("insert into users (password) values ('abc')"),
         DB.raw("select * from users where id = 7"),
         DB.raw("select * from users where id = 8"),
         DB.raw("select * from users where id = 9"),
         DB.raw("select * from users where id = 10"),
         DB.raw("insert into users (password) values ('abc')"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # # DB.raw("insert into users (password) values ('abc')"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # # DB.raw("insert into users (password) values ('abc')"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # # DB.raw("insert into users (password) values ('abc')"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("select * from users where id = 1"),
         # DB.raw("insert into users (password) values ('abc')"),
         # DB.raw("update users set password = 'foo'"),
         DB.commit(),
         {:ok, req} <- endpoint.get_context(req, params, session),
         context = req.context,
         {:ok, req} <- endpoint.handle_request(req, params, context, session),
         # store_events!(req.events),
         # DB.commit(),
         # emit_events!(req),
         result = req.result,
         {:ok, req} <- endpoint.render_response(req, result, session) do
      Endpoint.render_response(req)
    else
      {:error, req} ->
        # TODO: Determine if we should rollback
        Endpoint.render_response(req)
    end
  end

  defp do_dispatch(cowboy_request, %{handler: endpoint, scope: scope}) do
    request =
      cowboy_request
      |> Request.new(endpoint, scope)
      |> Conveyor.execute(@belts)

    {:ok, request.cowboy_request, request}
  end

  defp log_request(duration, %{
         cowboy_request: cowboy_request,
         conveyor: conveyor
       }) do
    method = cowboy_request.method |> String.upcase()
    path = cowboy_request.path
    resp_status = conveyor.response_status
    duration = get_duration(duration)
    Logger.info("#{method} #{path} - Served #{resp_status} in #{duration}")
  end

  defp get_duration(d) when d < 1000, do: "#{d}μs"
  defp get_duration(d) when d < 10_000, do: "#{Float.round(d / 1000, 2)}ms"
  defp get_duration(d) when d < 100_000, do: "#{Float.round(d / 1000, 1)}ms"
  defp get_duration(d), do: "#{trunc(d / 1000)}ms"
end
