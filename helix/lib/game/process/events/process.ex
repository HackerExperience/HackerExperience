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

    @type t :: %__MODULE__{
            process: Process.t(),
            confirmed: boolean
          }

    @name :process_created

    def new(process = %Process{}, confirmed: confirmed) do
      %__MODULE__{
        process: process,
        confirmed: confirmed
      }
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            id: integer(),
            type: binary()
          }),
          [:id, :type]
        )
      end

      def generate_payload(%{data: %{process: process}}) do
        # TODO: It doesn't make any sense to publish this process, at least while it hasn't been
        # confirmed yet. The request that created the process already has access to this information
        payload =
          %{
            id: process.id |> ID.to_external(),
            type: "#{process.type}"
          }

        {:ok, payload}
      end

      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end
  end

  # TODO: Should ProcessCompletedEvent be publishable? It may be how we tell the Client that
  # a process finished processing. Then at some point it will receive another event with the
  # actuall side-effect from whatever process was running.
  defmodule Completed do
    use Core.Event.Definition

    alias Game.Process

    defstruct [:process]

    @type t :: %__MODULE__{
            process: Process.t()
          }

    @name :process_completed

    def new(process = %Process{}) do
      %__MODULE__{process: process}
      |> Event.new()
    end

    def handlers(_, _) do
      [Handlers.Process.TOP]
    end
  end

  defmodule Killed do
    use Core.Event.Definition

    alias Game.Process

    defstruct [:process, :reason]

    @type t :: %__MODULE__{
            process: Process.t(),
            reason: atom
          }

    @name :process_killed

    def new(process = %Process{}, reason) when is_atom(reason) do
      %__MODULE__{process: process, reason: reason}
      |> Event.new()
    end
  end

  defmodule Paused do
    use Core.Event.Definition

    alias Game.Process

    defstruct [:process]

    @type t :: %__MODULE__{
            process: Process.t()
          }

    @name :process_paused

    def new(process = %Process{status: :paused}) do
      %__MODULE__{process: process}
      |> Event.new()
    end
  end

  defmodule Resumed do
    use Core.Event.Definition

    alias Game.Process

    defstruct [:process]

    @type t :: %__MODULE__{
            process: Process.t()
          }

    @name :process_resumed

    def new(process = %Process{status: :awaiting_allocation}) do
      %__MODULE__{process: process}
      |> Event.new()
    end
  end

  defmodule Reniced do
    use Core.Event.Definition

    alias Game.Process

    defstruct [:process]

    @type t :: %__MODULE__{
            process: Process.t()
          }

    @name :process_reniced

    def new(process = %Process{status: :running}) do
      %__MODULE__{process: process}
      |> Event.new()
    end
  end
end
