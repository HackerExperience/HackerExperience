defmodule Core.Event.Relay do
  defstruct [:source, :server_id, :request_id, :x_request_id]

  @available_sources [:request, :top]

  def new(source, data) when source in @available_sources do
    %__MODULE__{
      source: source,
      server_id: data[:server_id],
      request_id: data[:request_id],
      x_request_id: data[:x_request_id]
    }
  end
end
