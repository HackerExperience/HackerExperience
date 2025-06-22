defmodule Game.Endpoint.Software.Manifest do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  import Core.Endpoint

  alias Game.{Software}

  def input_spec do
    selection(
      schema(%{}),
      []
    )
  end

  def output_spec(200) do
    selection(
      schema(%{
        manifest: Software.Manifest.spec()
      }),
      [:manifest]
    )
  end

  def get_params(request, _parsed, _session),
    do: {:ok, %{request | params: %{}}}

  def get_context(request, _params, _session),
    do: {:ok, %{request | context: %{}}}

  def handle_request(request, _params, _ctx, _session),
    do: {:ok, %{request | result: %{software: Software.all()}}}

  def render_response(request, %{software: software}, _session) do
    manifest = Software.Manifest.render(software)
    {:ok, %{request | response: {200, %{manifest: manifest}}}}
  end
end
