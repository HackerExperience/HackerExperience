defmodule Game.Events.Process do
  defmodule Created do
    @moduledoc """
    `ProcessCreatedEvent` is fired when a process is created. This event has an initial optimistic
    behaviour, so it is fired in two different moments.

    First, it is fired from ProcessAction, right after the process is created and inserted in the
    database. At this stage, the Process is said to be optimistic (unconfirmed) because the server
    may not be able to allocate resources to this process.

    This same event may be fired again from the TOPHandler, in which case the allocation was
    successful and the process creation has been confirmed. We only publish to the Client if the
    process is confirmed as created.

    If creation fails, we emit the `ProcessCreateFailedEvent`.
    """

    use Core.Event.Definition

    alias Game.Process

    defstruct [:process, :confirmed]

    @name :process_created

    def new(process = %Process{}, confirmed: confirmed) do
      %__MODULE__{
        process: process,
        confirmed: confirmed
      }
    end

    def handlers(_, _), do: []
  end
end
