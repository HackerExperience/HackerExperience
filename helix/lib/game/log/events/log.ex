defmodule Game.Events.Log do
  defmodule Deleted do
    @moduledoc """
    The LogDeletedEvent is emitted after a Log is deleted, which is the direct result of a
    LogDeleteProcess reaching completion.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Log, Process}

    defstruct [:log, :process]

    @type t :: %__MODULE__{
            log: Log.t(),
            process: Process.t(:log_delete)
          }

    @name :log_deleted

    def new(log = %Log{}, process = %Process{}) do
      %__MODULE__{log: log, process: process}
      |> Event.new()
    end

    def handlers(_, _), do: [Handlers.Log]

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            nip: nip(),
            log_id: external_id(),
            process_id: external_id()
          }),
          [:nip, :log_id, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, log: log}}) do
        entity_id = process.entity_id
        server_id = process.server_id

        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server_id)

        payload =
          %{
            nip: NIP.to_external(nip),
            log_id: log.id |> ID.to_external(entity_id, server_id),
            process_id: process.id |> ID.to_external(entity_id, server_id)
          }

        {:ok, payload}
      end

      @doc """
      Everyone who has visibility on that log (any revision) receives the event (TODO)
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end
  end

  defmodule DeleteFailed do
    @moduledoc """
    The LogDeletedFailedEvent is emitted when the attempt to delete a Log has failed. This may
    happen during the execution of a LogDeleteProcess or at its completion if the prerequisites
    are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            # TODO: Narrow down possible reasons
            reason: term,
            process: Process.t(:log_delete)
          }

    @name :log_delete_failed

    def new(reason, %Process{} = process) do
      %__MODULE__{reason: reason, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            reason: binary(),
            process_id: external_id()
          }),
          [:reason, :process_id]
        )
      end

      def generate_payload(%{data: %{reason: reason, process: process}}) do
        entity_id = process.entity_id
        server_id = process.server_id

        payload =
          %{
            reason: reason,
            process_id: process.id |> ID.to_external(entity_id, server_id)
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
end
