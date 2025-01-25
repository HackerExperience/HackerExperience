defmodule Game.Process.Installation.Uninstall do
  use Game.Process.Definition

  require Logger

  alias Game.{Installation}

  defstruct [:installation_id]

  def new(_, %{installation: %Installation{} = installation}) do
    %__MODULE__{installation_id: installation.id}
  end

  def get_process_type(_, _), do: :installation_uninstall

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.Installation.Uninstalled, as: InstallationUninstalledEvent
    alias Game.Events.Installation.UninstallFailed, as: InstallationUninstallFailedEvent

    @spec on_complete(Process.t(:installation_uninstall)) ::
            {:ok, InstallationUninstalledEvent.event()}
            | {:error, InstallationUninstallFailedEvent.event()}
    def on_complete(
          %{
            server_id: server_id,
            entity_id: entity_id,
            registry: %{tgt_installation_id: %Installation.ID{} = installation_id}
          } = process
        ) do
      Core.begin_context(:server, process.server_id, :write)

      with {true, %{installation: installation}} <-
             Henforcers.Installation.can_uninstall?(server_id, entity_id, installation_id),
           {:ok, _} <- Svc.Installation.uninstall(installation) do
        Core.commit()
        {:ok, InstallationUninstalledEvent.new(installation, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to uninstall installation: #{reason}")
          {:error, InstallationUninstallFailedEvent.new(process, reason)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to uninstall installation: #{inspect(reason)}")
          {:error, InstallationUninstallFailedEvent.new(process, :internal)}
      end
    end

    defp format_henforcer_error({:installation, :not_found}), do: "installation_not_found"
    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _param, _meta) do
      # TODO
      5000
    end

    # TODO: Maybe IOPS? Or IOPS + CPU?
    def dynamic(_, _, _), do: [:cpu]

    def static(_, _, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
    alias Game.Installation

    @doc """
    This is the installation that the process is targeting, that is, that will be uninstalled.
    """
    def target_installation(_, _, _, %{installation: %Installation{} = installation}, _),
      do: installation
  end
end
