defmodule Webserver.Dispatcher do
  require Logger
  use Webserver.Conveyor.Belt
  alias Webserver.{Conveyor, Endpoint, Hooks, Request}
  alias Core.Event

  @behaviour :cowboy_handler
  @env Mix.env()

  @impl :cowboy_handler
  def init(cowboy_request, args) do
    {duration, {:ok, result, request}} = :timer.tc(fn -> do_dispatch(cowboy_request, args) end)

    # Log in a different process because sometimes Cowboy kills the request
    # process as soon as the response is sent and we may lose logs.
    # Note this may not happen in prod, but at least in dev it happens.
    spawn(fn -> log_request(duration, request) end)

    result
  end

  def info({ref, {:event_result, :ok}}, req, state) when is_reference(ref) do
    # Message received from the Event.emit/1 task
    {:ok, req, state}
  end

  def info({:DOWN, _ref, :process, _, _status}, req, state) do
    # TODO: A possible improvement is checking `ref` is the same `ref` as above
    {:ok, req, state}
  end

  def info(event, req, %{dispatcher: :sse} = state) do
    Webserver.SSE.info(event, req, state)
  end

  def info(e, req, state) do
    Logger.warning("Unhandled msg: #{inspect(e)} - #{inspect({req, state})}")
    {:ok, req, state}
  end

  @impl :cowboy_handler
  def terminate(:normal, _, _), do: :ok

  @impl :cowboy_handler
  def terminate(reason, req, state) do
    Logger.warning("Unexpected termination: #{inspect(reason)} - #{inspect({req, state})}")
    :ok
  end

  @doc """
  Belt entrypoint for the dispatcher. Actually dispatches the request to the corresponding handler.
  """
  @impl Webserver.Conveyor.Belt
  def call(req, _, _) do
    endpoint = Request.get_endpoint(req, @env)

    session = req.session
    true = not is_nil(session)

    with {:ok, req} <- Endpoint.validate_input(req, endpoint, req.raw_params),
         {:ok, req} <- endpoint.get_params(req, req.parsed_params, session),
         params = req.params,
         {:ok, req} <- Hooks.on_get_params_ok(req),
         {:ok, req} <- endpoint.get_context(req, params, session),
         context = req.context,
         {:ok, req} <- endpoint.handle_request(req, params, context, session),
         {:ok, req} <- Hooks.on_handle_request_ok(req),
         # store_events!(req.events),
         # DB.commit(),
         emit_events(req),
         result = req.result,
         {:ok, req} <- endpoint.render_response(req, result, session) do
      Endpoint.render_response(req, endpoint)
    else
      {:error, req} ->
        # This is a TODO. FeebDB should expose this kind of information. Also, we may want to roll
        # back within a hook instead of here (not sure though)
        case Process.get(:feebdb_current_context) do
          {_, _} ->
            Feeb.DB.rollback()

          _ ->
            :noop
        end

        Endpoint.render_response(req, endpoint)
    end
  end

  # defp do_dispatch(cowboy_request, %{handler: endpoint, scope: scope}) do
  defp do_dispatch(cowboy_request, %{handler: endpoint, webserver: webserver} = args) do
    request =
      cowboy_request
      |> Request.new(endpoint, webserver, args)
      |> Conveyor.execute()

    # Result that should be returned by the `init/2` call from the :cowboy_handler behaviour
    cowboy_result =
      case {request.cowboy_return, request.conveyor} do
        {:ok, _conveyor} ->
          {:ok, request.cowboy_request, %{}}

        {{:start_sse, state}, _conveyor} ->
          {:cowboy_loop, request.cowboy_request, state}

        # Request never reached the end of the conveyor belt because it was halted mid-way. As such,
        # we need to return whatever error code and reason was defined during the halting.
        # TODO: Maybe consider the possibility of a halted request being handled by a custom belt?
        {nil, %{halt?: true, response_status: error_code, response_message: _msg}} ->
          # TODO: For now, I'm ignoring `response_message`
          cowboy_request = :cowboy_req.reply(error_code, %{}, "", request.cowboy_request)
          {:ok, cowboy_request, %{}}
      end

    {:ok, cowboy_result, request}
  end

  defp log_request(duration, %{cowboy_request: cowboy_request, conveyor: conveyor}) do
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

  defp emit_events(%{events: []}), do: :ok

  defp emit_events(%{events: events} = req) when is_list(events) do
    # TODO: Find a way to synchronously wait events to finish executing (for tests)

    # TODO: Find a way to concentrate in a single module "dirty" state like this
    helix_universe_shard_id = req.session.shard_id
    helix_universe = Process.get(:helix_universe)

    # TODO: Test how the async process handles the parent request dying. This doesn't happen in the
    # SSE request because, in that case, the process lives indefinitely (see `:start_sse` above)
    Task.Supervisor.async_nolink(
      {:via, PartitionSupervisor, {Helix.TaskSupervisor, self()}},
      fn ->
        Process.put(:helix_universe, helix_universe)
        Process.put(:helix_universe_shard_id, helix_universe_shard_id)

        {:event_result, Event.emit(events)}
      end
    )
  end
end
