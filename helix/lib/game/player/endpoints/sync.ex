defmodule Game.Endpoint.Player.Sync do
  use Webserver.Endpoint
  use Core.Spec
  require Logger

  @behaviour Webserver.Endpoint.Behaviour

  def input_spec do
    selection(schema(%{}), [])
  end

  def output_spec(200) do
    selection(schema(%{}), [])
  end

  def get_params(request, _parsed, _session) do
    {:ok, request}
  end

  def get_context(request, _params, _session) do
    {:ok, request}
  end

  def handle_request(request, _params, _context, _session) do
    {:ok, request}
  end

  def render_response(request, _data, _session) do
    {:ok, %{request | response: {200, %{to: :do}}}}
  end
end
