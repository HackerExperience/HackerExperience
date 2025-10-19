defmodule Game.Events.Scanner do
  defmodule TaskCompleted do
    @moduledoc """
    The ScannerTaskCompletedEvent is emitted after a Scanner task reached its target completion
    date. It is consumed by domain-specific handlers for the purpose of adding visibility for the
    scanned objects.

    Not published to the client.
    """

    use Core.Event.Definition

    alias Game.ScannerTask

    defstruct [:task]

    @type t :: %__MODULE__{
            task: ScannerTask.t()
          }

    @name :scanner_task_completed

    def new(task = %ScannerTask{}) do
      %__MODULE__{task: task}
      |> Event.new()
    end

    # def handlers(_, %{data: %{task: %{type: :connection}}}), do: [Handlers.Log]
    # def handlers(_, %{data: %{task: %{type: :file}}}), do: [Handlers.Log]
    def handlers(_, %{data: %{task: %{type: :log}}}), do: [Handlers.Log]
  end
end
