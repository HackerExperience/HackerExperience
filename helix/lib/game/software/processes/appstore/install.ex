defmodule Game.Process.AppStore.Install do
  use Game.Process.Definition

  require Logger

  alias Game.{Software}

  defstruct [:software_type]

  def new(_, %{software: %Software{} = software}) do
    %__MODULE__{software_type: software.type}
  end

  def get_process_type(_, _), do: :appstore_install

  def on_db_load(%__MODULE__{} = raw) do
    raw
    |> Map.put(:software_type, String.to_existing_atom(raw.software_type))
  end

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
           {true, %{action: action} = install_relay} <-
             Henforcers.AppStore.can_install?(server, file_type),
           {:ok, %{file: file, installation: installation}} <-
             apply_action(server, entity, action, install_relay) do
        Core.commit()
        {:ok, AppStoreInstalledEvent.new(installation, file, action, process)}
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

    defp apply_action(server, entity, :download_and_install, %{software: software}) do
      file_params = get_software_creation_params(software)

      with {:ok, file} <- Svc.File.create_file(entity.id, server.id, file_params),
           {:ok, installation} <- Svc.File.install_file(file) do
        {:ok, %{file: file, installation: installation}}
      end
    end

    defp apply_action(_server, _entity, :install_only, %{matching_files: matching_files}) do
      file = List.first(matching_files)

      with {:ok, installation} <- Svc.File.install_file(file) do
        {:ok, %{file: file, installation: installation}}
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

    defp format_henforcer_error({_, :already_installed}), do: "file_already_installed"
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

    def spec do
      selection(
        schema(%{
          software_type: enum(Software.types(:installable) |> Enum.map(&to_string/1))
        }),
        [:software_type]
      )
    end

    def render_data(_, %{software_type: software_type}, _) do
      %{software_type: to_string(software_type)}
    end
  end
end
