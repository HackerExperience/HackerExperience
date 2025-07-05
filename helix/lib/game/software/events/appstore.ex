defmodule Game.Events.AppStore do
  defmodule Installed do
    @moduledoc """
    The AppStoreInstalledEvent is emitted after an AppStoreInstallProcess completes.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{File, Installation, Process}

    defstruct [:file, :installation, :action, :process]

    @type t :: %__MODULE__{
            file: File.t() | nil,
            installation: Installation.t() | nil,
            action: :download_and_install | :download_only | :install_only,
            process: Process.t(:appstore_install)
          }

    @name :appstore_installed

    @valid_actions [:download_and_install, :download_only, :install_only]

    def new(installation, file, action, process = %Process{}) when action in @valid_actions do
      %__MODULE__{installation: installation, file: file, action: action, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      # TODO: Enhance to include full File and Installation (Client needs both)
      def spec do
        selection(
          schema(%{
            installation_id: external_id(),
            file_name: binary(),
            memory_usage: integer(),
            process_id: external_id()
          }),
          [:installation_id, :file_name, :memory_usage, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, file: file, installation: installation}}) do
        entity_id = process.entity_id
        server_id = process.server_id

        payload =
          %{
            installation_id: installation.id |> ID.to_external(entity_id, server_id),
            file_name: file.name,
            memory_usage: installation.memory_usage,
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

  defmodule InstallFailed do
    @moduledoc """
    The AppStoreInstallFailedEvent is emitted when the attempt to install an AppStore software
    failed. This may happen during the execution of an AppStoreInstallProcess or at its completion
    if the prerequisites are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:reason, :process]

    @type t :: %__MODULE__{
            # TODO: Narrow down possible reasons
            reason: term,
            process: Process.t(:appstore_install)
          }

    @name :appstore_install_failed

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
