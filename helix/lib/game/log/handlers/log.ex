defmodule Game.Handlers.Log do
  alias Game.Process.TOP
  alias Game.Services, as: Svc

  alias Game.Events.Log.Deleted, as: LogDeletedEvent

  @behaviour Core.Event.Handler.Behaviour

  def on_event(%LogDeletedEvent{log: log}, _) do
    # Send a SIG_TGT_LOG_DELETED signal to processes that relied on this log (tgt_log_id)
    Svc.Process.list_registry(by_tgt_log_id: log.id)
    |> Enum.each(fn %{server_id: server_id, process_id: process_id} ->
      process = Svc.Process.fetch!(server_id, by_id: process_id)
      TOP.signal(process, :sig_tgt_log_deleted)
    end)

    :ok
  end
end
