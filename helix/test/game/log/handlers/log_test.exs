defmodule Game.Handlers.LogTest do
  use Test.DBCase, async: true
  import ExUnit.CaptureLog

  alias Game.Handlers.Log, as: LogHandler

  alias Game.Events.Scanner.TaskCompleted, as: ScannerTaskCompletedEvent

  setup [:with_game_db]

  describe "on_event/1 - ScannerTaskCompletedEvent" do
    test "adds the corresponding log visibility" do
      %{server: server, entity: entity} = Setup.server()
      log = Setup.log!(server.id)

      task =
        Setup.scanner_task!(
          completed: true,
          type: :log,
          entity_id: entity.id,
          server_id: server.id,
          target_id: log.id.id,
          target_sub_id: log.revision_id.id
        )

      # When processing the ScannerTaskCompletedEvent, we get a LogScannedEvent back
      event = ScannerTaskCompletedEvent.new(task)
      assert {:ok, log_scanned_event} = LogHandler.on_event(event.data, event)

      assert log_scanned_event.name == :log_scanned
      assert log_scanned_event.data.log_visibility.source == :scanner
      assert log_scanned_event.data.log_visibility.server_id == server.id
      assert log_scanned_event.data.log_visibility.entity_id == entity.id
      assert log_scanned_event.data.log_visibility.log_id == log.id
      assert log_scanned_event.data.log_visibility.revision_id == log.revision_id

      # The visibility was saved in the DB
      assert [log_scanned_event.data.log_visibility] == U.get_all_log_visibilities(entity.id)
    end

    test "performs a no-op when log does not exist" do
      # Nothing here exists -- no entity, no server, no log
      task = Setup.scanner_task!(completed: true, type: :log, target_id: 1, target_sub_id: 1)

      event = ScannerTaskCompletedEvent.new(task)

      log =
        capture_log(fn ->
          # Handles the scenario gracefully
          :ok = LogHandler.on_event(event.data, event)
        end)

      assert log =~ "LogScanner completed on a log that does not exist"
    end

    test "performs a no-op when log is already visible" do
      %{server: server, entity: entity} = Setup.server()
      log = Setup.log!(server.id, visible_by: entity.id)

      task =
        Setup.scanner_task!(
          completed: true,
          type: :log,
          entity_id: entity.id,
          server_id: server.id,
          target_id: log.id.id,
          target_sub_id: log.revision_id.id
        )

      event = ScannerTaskCompletedEvent.new(task)

      log =
        capture_log(fn ->
          # Handles the scenario gracefully
          :ok = LogHandler.on_event(event.data, event)
        end)

      assert log =~ "LogScanner completed on a log that is already visible"
    end
  end
end
