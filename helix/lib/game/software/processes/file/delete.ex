defmodule Game.Process.File.Delete do
  use Game.Process.Definition

  require Logger

  alias Game.{File}

  defstruct [:file_id]

  def new(_, %{file: %File{} = file}) do
    %__MODULE__{file_id: file.id}
  end

  def get_process_type(_, _), do: :file_delete

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.File.Deleted, as: FileDeletedEvent
    alias Game.Events.File.DeleteFailed, as: FileDeleteFailedEvent

    @spec on_complete(Process.t(:file_delete)) ::
            {:ok, FileDeletedEvent.event()}
            | {:error, FileDeleteFailedEvent.event()}
    def on_complete(%{registry: %{tgt_file_id: %File.ID{} = file_id}} = process) do
      Core.begin_context(:server, process.server_id, :write)

      with {true, %{server: server}} <- Henforcers.Server.server_exists?(process.server_id),
           {true, %{entity: entity}} <- Henforcers.Entity.entity_exists?(process.entity_id),
           {true, %{file: file}} <- Henforcers.File.can_delete?(server, entity, file_id),
           {:ok, _} <- Svc.File.delete(file) do
        Core.commit()
        {:ok, FileDeletedEvent.new(file, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to delete file: #{reason}")
          {:error, FileDeleteFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to delete file: #{inspect(reason)}")
          {:error, FileDeleteFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error({:file, :not_found}), do: "file_not_found"
    defp format_henforcer_error({:file_visibility, :not_found}), do: "file_not_found"
    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition

    @doc """
    The File we were about to delete was deleted in the meantime. Let's just kill this process (with
    the message that *this* process failed, because even though its final goal was reached, it was
    not reached by this process).
    """
    def on_sig_tgt_file_deleted(_, _), do: :delete
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

    def target_file(_server_id, _entity_id, _params, %{file: %File{} = file}, _),
      do: file
  end
end
