defmodule Game.Endpoint.Player.Sync do
  use Webserver.Endpoint
  use Core.Spec
  require Logger
  alias Game.Services, as: Svc

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

  def get_context(request, _params, %{data: %{type: :authenticated, player_id: player_id}}) do
    # TODO: verify that this user (and this session) isn't already subscribed to a sync endpoint
    {:ok, request}
  end

  def handle_request(request, _params, _context, _session) do
    # TODO: Maybe use ETS to register subscribed processes?
    {:ok, request}
  end

  def render_response(request, _data, _session) do
    {:ok, %{request | response: {200, %{to: :do}}}}
  end
end
