defmodule Webserver.Request do
  defstruct [
    :id,
    :cowboy_request,
    :conveyor,
    :endpoint,
    :scope,
    :session,
    :unsafe_params,
    :params,
    :context,
    :result,
    :events,
    :response
  ]

  def new(cowboy_request, endpoint, scope) do
    %__MODULE__{
      cowboy_request: cowboy_request,
      endpoint: endpoint,
      scope: scope
    }
  end
end
