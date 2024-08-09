defmodule Webserver.Request do
  alias Webserver.{Config}

  @env Mix.env()

  defstruct [
    :id,
    :cowboy_request,
    :conveyor,
    :belts,
    :endpoint,
    :endpoint_mock,
    :webserver,
    :session,
    :raw_params,
    :parsed_params,
    :params,
    :context,
    :result,
    :events,
    :response,
    :universe
  ]

  def new(cowboy_request, endpoint, webserver, xargs \\ %{}) do
    %__MODULE__{
      cowboy_request: cowboy_request,
      endpoint: endpoint,
      endpoint_mock: xargs[:endpoint_mock],
      webserver: webserver,
      belts: get_belts(webserver, xargs, @env)
    }
  end

  def get_endpoint(%{endpoint_mock: mock}, :test) when not is_nil(mock), do: mock
  def get_endpoint(%{endpoint: endpoint}, _), do: endpoint

  def get_belts(_, %{custom_belts: belts}, :test), do: belts
  def get_belts(webserver, _, _), do: Config.get_webserver_belts(webserver)
end
