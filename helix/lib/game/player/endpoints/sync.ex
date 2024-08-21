defmodule Game.Endpoint.Player.Sync do
  use Webserver.Endpoint
  use Core.Spec
  require Logger
  alias Game.Services, as: Svc
  alias Core.Session.State.SSEMapping
  alias Game.Events.Player.IndexRequested, as: IndexRequestedEvent

  @behaviour Webserver.Endpoint.Behaviour

  def input_spec do
    selection(
      schema(%{
        "token" => binary()
      }),
      []
    )
  end

  def output_spec(200) do
    selection(schema(%{}), [])
  end

  def get_params(request, _parsed, _session) do
    {:ok, request}
  end

  def get_context(request, params, %{data: %{type: :unauthenticated}} = session) do
    # We are dealing with the very first login from that user. We need to create the
    # player entry first and then proceed with the Sync request
    case Svc.Player.create(%{external_id: session.data.external_id}) do
      {:ok, player} ->
        # TODO: DRY this (with that Session module?)
        session_data = %{
          type: :authenticated,
          player_id: player.id,
          external_id: player.external_id
        }

        new_session = Map.put(session, :data, session_data)
        get_context(request, params, new_session)

      {:error, reason} ->
        Logger.error("Failed to create player: #{inspect(reason)}")
        {:error, %{request | response: {500, :error_creating_player}}}
    end
  end

  def get_context(request, _, %{data: %{type: :authenticated}} = session) do
    case SSEMapping.is_subscribed?(session.data.external_id, session.id) do
      false ->
        # NOTE: `session` in `get_context` may not be the same `session` in `handle_request`.
        # If the session is originally `type=unauthenticated`, then the `new_session` defined above
        # (which is the `session` here) will exist only in _this_ function. By design, there is no
        # way for a request to replace the session during the request processing. That's why we
        # are returning `new_session` in the `context`, so it can be used by `handle_request`.
        {:ok, %{request | context: %{session: session}}}

      true ->
        {:error, %{request | response: {422, :already_subscribed}}}
    end
  end

  # See comment in `get_context/3` to understand why `session` is handled by the `context`.
  def handle_request(request, _params, %{session: session}, _unreliable_session) do
    # TODO: Logging (needs prior logging infra)
    SSEMapping.subscribe(session.data.external_id, session.id, self())

    event = IndexRequestedEvent.new(session.data.player_id)

    {:ok, %{request | events: [event]}}
  end

  def render_response(request, _data, _session) do
    {:ok, %{request | response: {200, %{to: :do}}}}
  end
end
