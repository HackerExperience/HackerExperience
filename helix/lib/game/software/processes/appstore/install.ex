defmodule Game.Process.AppStore.Install do
  use Game.Process.Definition

  require Logger

  alias Game.{Software}

  defstruct [:software_type]

  def new(_, %{software: %Software{} = software}) do
    %__MODULE__{software_type: software.type}
  end

  def get_process_type(_, _), do: :appstore_install

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.AppStore.Installed, as: AppStoreInstalledEvent
    alias Game.Events.AppStore.InstallFailed, as: AppStoreInstallFailedEvent

    @spec on_complete(Process.t(:appstore_install)) ::
            {:ok, AppStoreInstalledEvent.event()}
            | {:error, AppStoreInstallFailedEvent.event()}
    def on_complete(process) do
      Core.begin_context(:server, process.server_id, :write)

      file_type = process.data.software_type

      with {true, %{entity: entity, target: server, access_type: :local}} <-
             Henforcers.Server.has_access?(process),
           {true, %{software: software}} <-
             Henforcers.AppStore.can_install?(server, entity, file_type),
           file_params = get_software_creation_params(software),
           {:ok, file} <- Svc.File.create_file(entity.id, server.id, file_params),
           {:ok, installation} <- Svc.File.install_file(file) do
        Core.commit()
        {:ok, AppStoreInstalledEvent.new(installation, file, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to install appstore software: #{inspect(reason)}")
          {:error, AppStoreInstallFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to install appstore software: #{inspect(reason)}")
          {:error, AppStoreInstallFailedEvent.new(:internal, process)}
      end
    end

    defp get_software_creation_params(software) do
      %{
        # TODO
        name: "Cracker",
        type: software.type,
        version: software.config.appstore[:version] || 10,
        size: software.config.appstore[:size] || 10,
        path: "/"
      }
    end

    defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
    defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
    defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _param, _meta) do
      # TODO (probably time-bound)
      5000
    end

    def dynamic(_, _, _), do: [:cpu]

    def static(_, _, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
  end

  defmodule Viewable do
    use Game.Process.Viewable.Definition

    # TODO: Enhance when implementing the View in the client

    def spec do
      selection(
        schema(%{}),
        []
      )
    end

    def render_data(_, _, _) do
      %{}
    end
  end
end
