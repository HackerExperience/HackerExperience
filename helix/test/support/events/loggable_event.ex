defmodule Test.LoggableEvent do
  use Core.Event.Definition

  defstruct [:log_map]

  @name :test_loggable_event

  def new(log_map) do
    %__MODULE__{log_map: log_map}
    |> Event.new()
  end

  def handlers(_, _) do
    []
  end

  defmodule Loggable do
    use Core.Event.Loggable.Definition
    def log_map(event), do: event.data.log_map
  end
end
