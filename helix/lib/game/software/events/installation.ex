defmodule Game.Events.Installation do
  defmodule Uninstalled do
    @moduledoc """
    The InstallationUninstalledEvent is emitted after an Installation is uninstalled, which is the
    direct result of a InstallationUninstallProcess reaching completion.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Installation, Process}

    defstruct [:installation, :process]

    @type t :: %__MODULE__{
            installation: Installation.t(),
            process: Process.t(:installation_uninstall)
          }

    @name :installation_uninstalled

    def new(installation = %Installation{}, process = %Process{}) do
      %__MODULE__{installation: installation, process: process}
      |> Event.new()
    end

    defmodule Publishable do
      use Core.Event.Publishable.Definition

      def spec do
        selection(
          schema(%{
            nip: nip(),
            installation_id: external_id(),
            process_id: external_id()
          }),
          [:nip, :installation_id, :process_id]
        )
      end

      def generate_payload(%{data: %{process: process, installation: installation}}) do
        entity_id = process.entity_id
        server_id = process.server_id
        %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server_id)

        payload =
          %{
            nip: NIP.to_external(nip),
            installation_id: installation.id |> ID.to_external(entity_id, server_id),
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

  defmodule UninstallFailed do
    @moduledoc """
    The InstallationUninstallFailedEvent is emitted when the attempt to uninstall an installation
    has failed. This may happen during the execution of a InstallationUninstallProcess or at its
    completion if the prerequisites are not met.

    This event is published to the Client.
    """

    use Core.Event.Definition

    alias Game.{Process}

    defstruct [:process, :reason]

    @type t :: %__MODULE__{
            process: Process.t(:installation_uninstall),
            # TODO: Narrow down possible reasons
            reason: term
          }

    @name :installation_uninstall_failed

    def new(process = %Process{}, reason) do
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
        entity_id = process.entity_id
        server_id = process.server_id

        payload =
          %{
            process_id: process.id |> ID.to_external(entity_id, server_id),
            reason: reason
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
