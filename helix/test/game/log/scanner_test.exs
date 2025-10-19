defmodule Game.Scanner.LogTest do
  use Test.DBCase, async: true
  alias Game.Log
  alias Game.Scanner.Log, as: LogScanner

  setup [:with_game_db]

  # TODO:
  # - test it does not bring logs older than 14 days

  describe "retarget/1 - no custom target_params" do
    test "finds the only log the user has no visibility over" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # Player has no visibility over this log
      log = Setup.log!(server.id)

      # Player has visibility over this single-revision log
      Setup.log!(server.id, visible_by: entity.id)

      # Player has visibility over this multi-revision log
      log_1_1 = Setup.log!(server.id, visible_by: entity.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 2, visible_by: entity.id)

      assert {:ok, target_id, _} = LogScanner.retarget(task)
      assert_target_id(log, target_id)
    end

    test "finds the next revision when player already has visibility over the last revision" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # This log has 4 revisions, out of which only the last is visible by `entity`
      log_1_1 = Setup.log!(server.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 2)
      log_1_3 = Setup.log!(server.id, id: log_1_1.id, revision_id: 3)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 4, visible_by: entity.id)

      assert {:ok, target_id, _} = LogScanner.retarget(task)
      assert_target_id(log_1_3, target_id)
    end

    test "finds the next revision when player has visibility over some revision" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # This scenario is less likely but could happen. Player has visibility over the fourth
      # revision, which is not the last one. Retarget must always pick rev 3 as next
      log_1_1 = Setup.log!(server.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 2)
      log_1_3 = Setup.log!(server.id, id: log_1_1.id, revision_id: 3)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 4, visible_by: entity.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 5)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 6)

      assert {:ok, target_id, _} = LogScanner.retarget(task)
      assert_target_id(log_1_3, target_id)
    end

    test "finds the latest revision when player has no prior visibility" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # This log has four revisions, none of which are visible by the player
      log_1_1 = Setup.log!(server.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 2)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 3)
      log_1_4 = Setup.log!(server.id, id: log_1_1.id, revision_id: 4)

      # The last revision must be the target
      assert {:ok, target_id, _} = LogScanner.retarget(task)
      assert_target_id(log_1_4, target_id)
    end

    test "returns empty when server has no logs" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # No logs in the server
      assert [] = U.get_all_logs(server.id)

      assert {:ok, :empty} == LogScanner.retarget(task)
    end

    test "returns empty when player already has access to all logs (single rev)" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # Player has visibility over the only two logs in the server
      Setup.log!(server.id, visible_by: entity.id)
      Setup.log!(server.id, visible_by: entity.id)

      assert {:ok, :empty} == LogScanner.retarget(task)
    end

    test "returns empty when player already has access to all revisions of all logs" do
      %{server: server, entity: entity} = Setup.server()
      task = setup_task(server, entity)

      # Player has visibility over all 3 revisions of the log
      log_1_1 = Setup.log!(server.id, visible_by: entity.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 2, visible_by: entity.id)
      Setup.log!(server.id, id: log_1_1.id, revision_id: 3, visible_by: entity.id)

      assert {:ok, :empty} == LogScanner.retarget(task)
    end
  end

  describe "find_logs/3 - recent bias" do
    test "picks a log from the most recent list" do
      logs = [[10, 1], [9, 1], [8, 1], [7, 1], [6, 1], [5, 1], [4, 1], [3, 1], [2, 1], [1, 1]]
      visibilities = []

      # At 10 log entries with 30% as `@recent_factor`, one of the first 3 logs must be picked
      assert [selected_log_id, _] = LogScanner.find_log({logs, 10}, {visibilities, 0}, %{})
      assert selected_log_id in [10, 9, 8]
    end

    test "takes visibility into consideration when selecting most recent list" do
      logs = [[10, 1], [9, 1], [8, 1], [7, 1], [6, 1], [5, 1], [4, 1], [3, 1], [2, 1], [1, 1]]
      visibilities = [[10, 1], [9, 1]]

      # {8, 1} *must* be selected, as it's the only one in the recent list that hasn't been found
      assert [8, 1] == LogScanner.find_log({logs, 10}, {visibilities, 2}, %{})
    end

    test "fallbacks to 'old' list when recent is fully visible" do
      logs = [[10, 1], [9, 1], [8, 1], [7, 1], [6, 1], [5, 1], [4, 1], [3, 1], [2, 1], [1, 1]]
      visibilities = [[10, 1], [9, 1], [8, 1]]

      # Since the recent list is fully visible, falls back to the older logs and picks one of them
      assert [selected_log_id, _] = LogScanner.find_log({logs, 10}, {visibilities, 3}, %{})
      assert selected_log_id in [7, 6, 5, 4, 3, 2, 1]
    end
  end

  defp setup_task(server, entity) do
    instance =
      Setup.scanner_instance!(
        completed: true,
        type: :log,
        server_id: server.id,
        entity_id: entity.id
      )

    Setup.scanner_task!(instance: instance)
  end

  defp assert_target_id(%Log{id: log_id, revision_id: revision_id}, target_id),
    do: assert(target_id == {log_id.id, revision_id.id})
end
