defmodule Game.Handlers.Log do
  require Logger

  alias Game.Process.TOP
  alias Game.Services, as: Svc

  alias Game.Events.Log.Deleted, as: LogDeletedEvent
  alias Game.Events.Log.Scanned, as: LogScannedEvent
  alias Game.Events.Scanner.TaskCompleted, as: ScannerTaskCompletedEvent

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

  def on_event(
        %ScannerTaskCompletedEvent{
          task: %{
            type: :log,
            server_id: server_id,
            entity_id: entity_id,
            target_id: raw_log_id,
            target_sub_id: raw_revision_id
          }
        },
        _
      ) do
    with {:log, %_{} = log} <-
           {:log, Svc.Log.fetch(server_id, by_id_and_revision_id: {raw_log_id, raw_revision_id})},
         {:visibility, nil} <- {:visibility, Svc.Log.fetch_visibility(entity_id, by_log: log)},
         {:ok, %_{} = log_visibility} <- Svc.Log.find_log(log, entity_id, server_id) do
      {:ok, LogScannedEvent.new(log_visibility)}
    else
      {:log, nil} ->
        Logger.warning("LogScanner completed on a log that does not exist - ignoring")
        :ok

      {:visibility, %_{}} ->
        Logger.warning("LogScanner completed on a log that is already visible - ignoring")
        :ok
    end
  end

  def on_prepare_db(%LogDeletedEvent{}, _), do: {:universe, :read}
  def on_prepare_db(%ScannerTaskCompletedEvent{}, _), do: :skip

  # TODO: Maybe merge "on_success" and "on_failure" in a single callback? They always come in pairs
  def teardown_db_on_success(%LogDeletedEvent{}, _), do: :commit
  def teardown_db_on_success(%ScannerTaskCompletedEvent{}, _), do: :skip

  def teardown_db_on_failure(%LogDeletedEvent{}, _), do: :rollback
  def teardown_db_on_failure(%ScannerTaskCompletedEvent{}, _), do: :skip
end
