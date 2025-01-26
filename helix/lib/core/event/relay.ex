defmodule Core.Event.Relay do
  alias Game.Process

  defstruct [:source, :server_id, :process_id, :request_id, :x_request_id]

  @available_sources [:request, :top, :process]

  def set(%Process{} = process),
    do: set(:process, %{server_id: process.server_id, process_id: process.id})

  def set(source, data) when source in @available_sources do
    %__MODULE__{
      source: source,
      server_id: data[:server_id],
      process_id: data[:process_id],
      request_id: data[:request_id],
      x_request_id: data[:x_request_id]
    }
    |> tap(&Elixir.Process.put(:helix_event_relay, &1))
  end
end
