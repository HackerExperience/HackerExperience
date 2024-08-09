defmodule Webserver.Request do
  defstruct [
    :id,
    :cowboy_request,
    :conveyor,
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
      webserver: webserver
    }
  end

  def get_endpoint(%{endpoint_mock: mock}, :test) when not is_nil(mock), do: mock
  def get_endpoint(%{endpoint: endpoint}, _), do: endpoint
end
