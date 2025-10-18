defmodule Core.Event.Relay do
  alias Core.Event
  alias Game.{Process, ScannerTask}

  defstruct [
    :source_event_id,
    :process_id,
    :request_id,
    :scanner_instance_id,
    :scanner_task_id,
    :server_id,
    :source,
    :x_request_id
  ]

  @available_sources [:event, :process, :request, :scanner, :top]

  def new(%Process{server_id: server_id, id: process_id}),
    do: new(:process, %{server_id: server_id, process_id: process_id})

  def new(%ScannerTask{run_id: task_id, instance_id: instance_id, server_id: server_id}) do
    new(:scanner, %{
      server_id: server_id,
      scanner_instance_id: instance_id,
      scanner_task_id: task_id
    })
  end

  def new(%Event{id: parent_event_id}),
    do: new(:event, %{source_event_id: parent_event_id})

  def new(source, data) when source in @available_sources do
    %__MODULE__{
      source: source,
      source_event_id: data[:source_event_id],
      process_id: data[:process_id],
      request_id: data[:request_id],
      scanner_instance_id: data[:scanner_instance_id],
      scanner_task_id: data[:scanner_task_id],
      server_id: data[:server_id],
      x_request_id: data[:x_request_id]
    }
  end

  def set_env(%__MODULE__{} = relay),
    do: Elixir.Process.put(:helix_event_relay, relay)

  def put(%Event{relay: nil} = event, %__MODULE__{} = relay),
    do: %{event | relay: relay}
end
