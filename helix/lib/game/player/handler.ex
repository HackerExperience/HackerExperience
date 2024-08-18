defmodule Game.Handlers.Player do
  use Core.Event.Handler
  alias Game.Events.Player.IndexRequested, as: IndexRequestedEvent

  def on_event(%IndexRequestedEvent{}, _) do
    # TODO
    :ok
  end
end
