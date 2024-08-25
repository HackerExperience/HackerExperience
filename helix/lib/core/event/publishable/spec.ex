defmodule Core.Event.Publishable.Spec do
  def spec do
    %{
      type: :events,
      title: "Events API",
      version: "1.0.0",
      endpoints: events()
    }
  end

  defp events do
    # It'd be interesting if we could "query" every module that uses a specific behaviour...

    [
      Game.Events.Player.IndexRequested
    ]
  end
end
