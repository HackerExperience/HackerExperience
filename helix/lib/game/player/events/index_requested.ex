defmodule Game.Events.Player.IndexRequested do
  use Core.Event

  defstruct []

  def new do
    %__MODULE__{}
    |> Event.new()
  end

  def handlers(_data, _event) do
    [Game.Handlers.Player]
  end
end
