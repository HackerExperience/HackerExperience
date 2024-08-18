defmodule Core.Event.Relay do
  defstruct [:request_id, :x_request_id]

  def new(request_id, x_request_id) do
    %__MODULE__{
      request_id: request_id,
      x_request_id: x_request_id
    }
  end
end
