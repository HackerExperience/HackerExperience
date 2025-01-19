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

      # TODO: Consider moving this Henforcer block into a "shared" top-level Henforcer to avoid
      # duplication with the Endpoint Henforcers.
      with {true, %{server: server}} <- Henforcers.Server.server_exists?(process.server_id),
           {true, _} <- Henforcers.Server.server_belongs_to_entity?(server, process.entity_id),
           {true, %{file: file}} <- Henforcers.File.file_exists?(file_id, server),
           {true, _} <- Henforcers.File.is_visible?(file, process.entity_id),
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
    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition

    # TODO: Kill process when source file is deleted
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
