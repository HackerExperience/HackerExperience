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
  end

  defmodule Completed do
    @moduledoc """
    ProcessCompletedEvent is emitted after a Process reached its objective and was "processed" by
    the TOP. At this point, the Process no longer exists in the Database, it is gone! The TOPHandler
    will pick this process and trigger the `Processable.on_complete/1` logic in the corresponding
    process.

    This event is published to the Client. A Client that receives this process knows that the
    Process is complete (and therefore should no longer show up in the TaskManager), but that's it.
    Soon, another event will be sent with more details about the side-effect/implications of this
    process completion. That's the responsibility of the `Processable.on_complete/1` trigger.

    Notice that even though the Process completed, it's entirely possible that its intended side
    effect was *not* reached successfully, for a variety of Process-specific reasons.
    """

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

    defmodule Publishable do
      use Core.Event.Publishable.Definition
      alias Game.Process.Viewable

      def spec do
        Viewable.spec(:nip)
      end

      def generate_payload(%{data: %{process: process}}) do
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: process.server_id)

        payload =
          process
          |> Viewable.render(process.entity_id)
          |> Map.merge(%{nip: NIP.to_external(nip)})

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives this event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
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

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            process_id: external_id(),
            reason: binary()
          }),
          [:process_id, :reason]
        )
      end

      def generate_payload(%{data: %{process: process, reason: reason}}) do
        payload = %{
          process_id: process.id |> ID.to_external(process.entity_id, process.server_id),
          reason: "#{reason}"
        }

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives this event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
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
