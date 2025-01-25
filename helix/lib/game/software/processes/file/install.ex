defmodule Game.Process.File.Install do
  use Game.Process.Definition

  require Logger

  alias Game.{File}

  defstruct [:file_id]

  def new(_, %{file: %File{} = file}) do
    %__MODULE__{file_id: file.id}
  end

  def get_process_type(_, _), do: :file_install

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.File.Installed, as: FileInstalledEvent
    alias Game.Events.File.InstallFailed, as: FileInstallFailedEvent

    @spec on_complete(Process.t(:file_install)) ::
            {:ok, FileInstalledEvent.event()}
            | {:error, FileInstallFailedEvent.event()}
    def on_complete(%{registry: %{src_file_id: %File.ID{} = file_id}} = process) do
      Core.begin_context(:server, process.server_id, :write)

      with {true, %{entity: entity, target: server}} <- Henforcers.Server.has_access?(process),
           {true, %{file: file}} <- Henforcers.File.can_install?(server, entity, file_id),
           {:ok, installation} <- Svc.File.install_file(file) do
        Core.commit()
        {:ok, FileInstalledEvent.new(installation, file, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to install file: #{reason}")
          {:error, FileInstallFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to install file: #{inspect(reason)}")
          {:error, FileInstallFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
    defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
    defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition

    @doc """
    If the File we are about to install was deleted, then we have no option but to kill ourselves.
    """
    def on_sig_src_file_deleted(_, _), do: :delete
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
    alias Game.File

    def source_file(_server_id, _entity_id, _params, %{file: %File{} = file}, _),
      do: file
  end
end
