defmodule Game.Events.AppStore do
  defmodule Installed do
    @moduledoc """
    The AppStoreInstalledEvent is emitted after an AppStoreInstallProcess completes.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{File, Installation, Process}
    alias Game.Index

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

      def spec do
        selection(
          schema(%{
            nip: nip(),
            file: maybe(Index.File.spec()),
            installation: maybe(Index.Installation.spec()),
            process_id: external_id()
          }),
          [:nip, :file, :installation, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, file: file, installation: installation}}) do
        entity_id = process.entity_id
        server_id = process.server_id
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server_id)

        # TODO: Always return the full file and full installation, inconditionally. It will simplify
        # the client-side logic.
        file =
          if file do
            Index.File.render_file({file, nil}, process.entity_id)
          end

        installation =
          if installation do
            Index.Installation.render_installation(installation, process.entity_id)
          end

        payload =
          %{
            nip: NIP.to_external(nip),
            file: file,
            installation: installation,
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
