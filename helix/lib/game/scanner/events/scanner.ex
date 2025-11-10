defmodule Game.Events.Scanner do
  defmodule InstancesCreated do
    @moduledoc """
    The ScannerInstancesCreatedEvent is emmited after a Scanner instance is (re-)created. This
    happens either on player login (for Gateway instances) or on remote server login (for
    Endpoint instances). All Entity/Server Instances are sent in a single event

    Published to the client.
    """

    use Core.Event.Definition

    alias Game.{Entity, ScannerInstance, Server}

    defstruct [:entity_id, :server_id, :instances]

    @type t :: %__MODULE__{
            entity_id: Entity.id(),
            server_id: Server.id(),
            instances: [ScannerInstance.t()]
          }

    @name :scanner_instances_created

    def new(instances) when is_list(instances) do
      [instance | _] = instances

      %__MODULE__{
        entity_id: instance.entity_id,
        server_id: instance.server_id,
        instances: instances
      }
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            nip: nip(),
            instances: coll_of(Index.Scanner.spec())
          }),
          [:nip, :instances]
        )
      end

      def generate_payload(%{
            data: %{server_id: server_id, entity_id: entity_id, instances: instances}
          }) do
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server_id)

        payload =
          %{
            nip: NIP.to_external(nip),
            instances: Enum.map(instances, &Index.Scanner.render_instance(&1, entity_id))
          }

        {:ok, payload}
      end

      def whom_to_publish(%{data: %{entity_id: entity_id}}),
        do: %{player: entity_id}
    end
  end

  defmodule InstanceEdited do
    @moduledoc """
    The ScannerInstanceEditedEvent is emitted after a ScannerInstance is edited, which is the direct
    result of a ScannerEditProcess reaching completion.

    This event is published to the client.
    """

    use Core.Event.Definition

    alias Game.{Process, ScannerInstance}

    defstruct [:process, :instance]

    @type t :: %__MODULE__{
            instance: ScannerInstance.t(),
            process: Process.t(:scanner_edit)
          }

    @name :scanner_instance_edited

    def new(instance = %ScannerInstance{}, process = %Process{}) do
      %__MODULE__{instance: instance, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            nip: nip(),
            instance: Index.Scanner.spec()
          }),
          [:nip, :instance]
        )
      end

      def generate_payload(%{data: %{process: process, instance: instance}}) do
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: process.server_id)

        payload =
          %{
            nip: NIP.to_external(nip),
            instance: Index.Scanner.render_instance(instance, process.entity_id)
          }

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives the event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end
  end

  defmodule InstanceEditFailed do
    @moduledoc """
    The ScannerInstanceEditFailedEvent is emitted when the attempt to edit a ScannerInstance has
    failed. This may happen when the pre-requisites of the ScannerEditProcess are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            reason: term,
            process: Process.t(:scanner_edit)
          }

    @name :scanner_instance_edit_failed

    def new(reason, %Process{} = process) do
      %__MODULE__{reason: reason, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            nip: nip(),
            reason: binary(),
            process_id: external_id()
          }),
          [:nip, :reason, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, reason: reason}}) do
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: process.server_id)

        payload =
          %{
            nip: NIP.to_external(nip),
            reason: reason,
            process_id: process.id,
            instance_id: process.data.instance_id
          }

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives the event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end
  end

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
