defmodule Game.Process.Log.Delete do
  use Game.Process.Definition

  alias Game.{Log}

  defstruct [:log_id]

  def new(_, %{log: %Log{} = log}) do
    %__MODULE__{
      log_id: log.id
    }
  end

  def get_process_type(_params, _meta) do
    :log_delete
  end

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.Log.Deleted, as: LogDeletedEvent
    alias Game.Events.Log.DeleteFailed, as: LogDeleteFailedEvent

    def on_complete(%{registry: %{tgt_log_id: %Log.ID{} = log_id}} = process) do
      # TODO: This should be done at a higher level (automatically for all Processable)
      Core.Event.Relay.set(process)

      Core.begin_context(:server, process.server_id, :write)

      with {true, %{entity: entity, target: server}} <- Henforcers.Server.has_access?(process),
           {true, %{log: log}} <- Henforcers.Log.can_delete?(server, entity, log_id),
           :ok <- Svc.Log.delete(log, entity.id),
           # Fetch the log again, so the event has the latest modified version
           log = Svc.Log.fetch!(server.id, by_id_and_revision_id: {log.id, log.revision_id}) do
        Core.commit()
        {:ok, LogDeletedEvent.new(log, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to delete log: #{reason}")
          {:error, LogDeleteFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to delete log: #{inspect(reason)}")
          {:error, LogDeleteFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
    defp format_henforcer_error({:tunnel, :not_found}), do: "tunnel_not_found"
    defp format_henforcer_error({:log, :not_found}), do: "log_not_found"
    defp format_henforcer_error({:log, :deleted}), do: "log_already_deleted"
    defp format_henforcer_error({:log_visibility, :not_found}), do: "log_not_found"
    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _params, _meta) do
      # TODO
      5000
    end

    def dynamic(_, _, _), do: [:cpu]

    def static(_, _, _) do
      %{
        paused: %{ram: 1},
        running: %{ram: 2}
      }
    end
  end

  defmodule Executable do
    alias Game.Log

    @type meta ::
            %{
              log: Log.t()
            }

    def target_log(_server_id, _entity_id, _params, %{log: log}, _),
      do: log
  end
end
