defmodule Game.Process.Processable do
  alias Core.Event
  alias Game.Process

  def on_complete(%Process{data: %process_mod{}} = process) do
    processable = get_processable(process_mod)

    # Add the Process to the Event relay, since an event will likely be emitted.
    process
    |> Event.Relay.new()
    |> Event.Relay.set_env()

    apply(processable, :on_complete, [process])
  end

  defp get_processable(process_mod),
    do: Module.concat(process_mod, :Processable)
end
