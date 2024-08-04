defmodule Webserver.Request do
  defstruct [
    :id,
    :cowboy_request,
    :conveyor,
    :endpoint,
    :webserver,
    :session,
    :raw_params,
    :parsed_params,
    :params,
    :context,
    :result,
    :events,
    :response
  ]

  def new(cowboy_request, endpoint, webserver) do
    %__MODULE__{
      cowboy_request: cowboy_request,
      endpoint: endpoint,
      webserver: webserver
    }
  end
end
