defmodule Game.Events.File do
  defmodule Installed do
    @moduledoc """
    The FileInstalledEvent is emitted after an Installation is done, which is the direct result of
    a FileInstallProcess reaching completion.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{File, Installation, Process}

    defstruct [:file, :installation, :process]

    @type t :: %__MODULE__{
            file: File.t(),
            installation: Installation.t(),
            process: Process.t(:file_install)
          }

    @name :file_installed

    def new(installation = %Installation{}, file = %File{}, process = %Process{}) do
      %__MODULE__{installation: installation, file: file, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            installation_id: integer(),
            file_name: binary(),
            memory_usage: integer(),
            process_id: integer()
          }),
          [:installation_id, :file_name, :memory_usage, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, file: _file, installation: installation}}) do
        payload =
          %{
            installation_id: installation.id,
            # file_name: file.name,
            file_name: "todo",
            memory_usage: installation.memory_usage,
            process_id: process.id
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

  defmodule InstallFailed do
    @moduledoc """
    The FileInstalledFailedEvent is emitted when the attempt to install a file has failed. This may
    happen during the execution of a FileInstallProcess or at its completion if the prerequisites
    are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            # TODO: Narrow down possible reasons
            reason: term,
            process: Process.t(:file_install)
          }

    @name :file_install_failed

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
            process_id: integer()
          }),
          [:reason, :process_id]
        )
      end

      def generate_payload(%{data: %{reason: reason, process: process}}) do
        payload =
          %{
            reason: reason,
            process_id: process.id
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

  defmodule Deleted do
    @moduledoc """
    The FileDeletedEvent is emitted after a File is deleted, which is the direct result of a
    FileDeleteProcess reaching completion.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{File, Process}

    defstruct [:file, :process]

    @type t :: %__MODULE__{
            file: File.t(),
            process: Process.t(:file_install)
          }

    @name :file_deleted

    def new(file = %File{}, process = %Process{}) do
      %__MODULE__{file: file, process: process}
      |> Event.new()
    end

    def handlers(_, _), do: [Handlers.File]

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            file_id: integer(),
            process_id: integer()
          }),
          [:file_id, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, file: file}}) do
        payload =
          %{
            file_id: file.id |> ID.to_external(),
            process_id: process.id |> ID.to_external()
          }

        {:ok, payload}
      end

      @doc """
      Only the Process owner receives this event.
      """
      def whom_to_publish(%{data: %{process: %{entity_id: entity_id}}}),
        do: %{player: entity_id}
    end

    defmodule Loggable do
      use Core.Event.Loggable.Definition
      alias Game.{File}

      def log_map(%{data: %{process: process, file: file}}) do
        tunnel_id = process.registry[:src_tunnel_id]

        # TODO: Loggable could accept a process instead, simplifying the API
        %{
          entity_id: process.entity_id,
          target_id: process.server_id,
          tunnel_id: tunnel_id,
          type: :file_deleted,
          data: %{
            gateway: %{file: file},
            endpoint: %{file: file}
          }
        }
      end
    end
  end

  defmodule DeleteFailed do
    @moduledoc """
    The FileDeletedFailedEvent is emitted when the attempt to delete a file has failed. This may
    happen during the execution of a FileDeleteProcess or at its completion if the prerequisites
    are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            # TODO: Narrow down possible reasons
            reason: term,
            process: Process.t(:file_delete)
          }

    @name :file_delete_failed

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
            process_id: integer()
          }),
          [:reason, :process_id]
        )
      end

      def generate_payload(%{data: %{reason: reason, process: process}}) do
        payload =
          %{
            reason: reason,
            process_id: process.id |> ID.to_external()
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
