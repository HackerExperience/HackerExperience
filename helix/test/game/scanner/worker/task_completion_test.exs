defmodule Game.Scanner.Worker.TaskCompletionTest do
  use Test.DBCase, async: true

  import Mox

  alias Game.ScannerTask
  alias Game.Scanner.Worker.TaskCompletion, as: TaskCompletionWorker

  setup [:with_game_db, :verify_on_exit!]

  setup do
    universe = Process.get(:helix_universe)
    shard_id = Process.get(:helix_universe_shard_id)

    {:ok, pid} = start_supervised({TaskCompletionWorker, [universe, shard_id]})

    %{pid: pid}
  end

  describe "genserver" do
    test "full lifecycle", %{pid: pid} do
      task_1 = Setup.scanner_task!(completed: true, type: :log)
      task_2 = Setup.scanner_task!(completed: true, type: :file, target_id: 5)
      _task_3 = Setup.scanner_task!(type: :connection)
      Core.commit()

      initial_state = :sys.get_state(pid)

      Game.Scanner.ScanneableMock
      |> expect(:retarget, 2, fn
        # Simulate the :log scanner returning {1, 2} and :file returning :empty
        %ScannerTask{type: :log} -> {:ok, {1, 2}, 60}
        %ScannerTask{type: :file} -> {:ok, :empty}
      end)

      Core.EventMock
      |> expect(:emit_async, fn events ->
        # There is only one event here, and that should be the File one. Why not the :log event when
        # it's completed as well? Because it has no target, and as such nothing to be made visible.
        assert [event] = events

        assert event.name == :scanner_task_completed
        assert event.data.task.type == :file
        assert event.data.task.target_id == 5

        :ok
      end)

      Mox.allow(Core.EventMock, self(), pid)
      Mox.allow(Game.Scanner.ScanneableMock, self(), pid)

      # Let's trigger the `:refresh` manually for testing purposes
      send(pid, :refresh)

      state = :sys.get_state(pid)

      # Right after `:refresh` run, the state was updated to account the fact that tasks 1 and 2
      # need to be processed.
      assert [{task_a, _, _}, {task_b, _, _}] = state.processing_tasks

      # Let's monitor both process so we know when they are done
      monitor_processing_tasks(state)

      scheduled_task_1 = Enum.find([task_a, task_b], &(&1.instance_id == task_1.instance_id))
      scheduled_task_2 = Enum.find([task_a, task_b], &(&1.instance_id == task_2.instance_id))
      assert scheduled_task_1 == task_1
      assert scheduled_task_2 == task_2

      # There is no completed task yet
      assert state.completed_tasks == []

      # There is no batch_writer timer created yet
      refute state.batch_writer_timer

      # We are still on the first batch
      assert state.batch_id == 1

      # The refresh timer has changed (will wake up again in @refresh_interval ms)
      refute state.refresh_timer == initial_state.refresh_timer

      # Wait for processing tasks to complete
      wait_processing_tasks(state)

      state = :sys.get_state(pid)

      # The completed tasks are stored in the state with the corresponding targets
      assert [{task_a, _, _, result_a}, {task_b, _, _, result_b}] = state.completed_tasks

      assert {_completed_task_1, task_1_result} =
               Enum.find([{task_a, result_a}, {task_b, result_b}], fn r ->
                 elem(r, 0).instance_id == task_1.instance_id
               end)

      assert {_completed_task_2, task_2_result} =
               Enum.find([{task_a, result_a}, {task_b, result_b}], fn r ->
                 elem(r, 0).instance_id == task_2.instance_id
               end)

      # As per the Mox expectations set above, each task holds the expected result
      assert task_1_result == {:ok, {1, 2}, 60}
      assert task_2_result == {:ok, :empty}

      # A timer was set to batch-write the recently updated tasks
      assert is_reference(state.batch_writer_timer)

      # Now we'll cancel the batch writer timer and trigger it manually
      assert Process.cancel_timer(state.batch_writer_timer)
      send(pid, :batch_writer)

      state = :sys.get_state(pid)

      # Now that we've batch-written the changes, we are in the next batch
      assert state.batch_id == 2
      refute state.batch_writer_timer

      # No more processing (or completed) tasks -- these will be re-populated in the next :refresh
      assert state.processing_tasks == []
      assert state.completed_tasks == []

      # And more importantly, let's make sure the DB changes were effective
      Core.with_context(:scanner, :read, fn ->
        ts_now = Renatils.DateTime.ts_now()

        # For :log scanner, run_id has changed and targets have been updated
        new_task_1 = DB.reload!(task_1)
        refute new_task_1.run_id == task_1.run_id
        assert new_task_1.target_id == 1
        assert new_task_1.target_sub_id == 2

        # If we subtract the completion date with the current timestamp, we get +- 60s (duration)
        assert_in_delta(ts_now + 60, new_task_1.completion_date, 10)

        # For :file scanner, run_id has changed but target is empty now
        new_task_2 = DB.reload!(task_2)
        refute new_task_2.run_id == task_2.run_id

        # The `target_id` changed from 5 to nil
        assert task_2.target_id == 5
        assert new_task_2.target_id == nil
        assert new_task_2.target_sub_id == nil
      end)
    end

    test "publishes ScannerTaskCompletedEvent for each completed task", %{pid: pid} do
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

      Core.commit()

      # This task is about to find `log` for `entity` on `server`
      assert task.server_id == server.id
      assert task.entity_id == entity.id
      assert task.target_id == log.id.id
      assert task.target_sub_id == log.revision_id.id

      Game.Scanner.ScanneableMock
      |> expect(:retarget, fn _ -> {:ok, :empty} end)

      Core.EventMock
      |> expect(:emit_async, fn events ->
        # There is only one event here, and that should be the File one. Why not the :log event when
        # it's completed as well? Because it has no target, and as such nothing to be made visible
        assert [event] = events

        assert event.name == :scanner_task_completed
        assert event.data.task == task

        # For the purpose of this test, we'll actually emit the event
        Core.Event.emit_async(events)
      end)

      Mox.allow(Core.EventMock, self(), pid)
      Mox.allow(Game.Scanner.ScanneableMock, self(), pid)

      # Let's trigger the `:refresh` manually for testing purposes
      send(pid, :refresh)

      # Make sure log is now visible by the player. First we wait until ScannerTaskCompletedEvent
      # is emitted. Then, LogScannedEvent will be emitted as soon as the ScannerTask is processed
      assert [scanner_task_completed_event] = wait_events!(scanner_task_id: task.run_id)
      assert [log_scanned_event] = wait_events!(source_event_id: scanner_task_completed_event.id)

      # After all that trouble, the original `log` is now visible by `entity`
      assert [log_visibility] = U.get_all_log_visibilities(entity.id)
      assert log_visibility.source == :scanner
      assert log_visibility.log_id == log.id
      assert log_visibility.revision_id == log.revision_id

      # The visibility is the same in the event that will be sent to the player
      assert log_scanned_event.name == :log_scanned
      assert log_scanned_event.data.log_visibility == log_visibility
    end
  end

  defp monitor_processing_tasks(%{processing_tasks: processing_tasks}) do
    processing_tasks
    |> Enum.map(fn {_, _, pid} -> pid end)
    |> Enum.each(&Process.monitor/1)
  end

  defp wait_processing_tasks(%{processing_tasks: processing_tasks}) do
    processing_tasks
    |> Enum.map(fn {_, _, pid} -> pid end)
    |> Enum.each(fn pid ->
      assert_receive {:DOWN, _, :process, ^pid, _}, 1_000
    end)
  end
end
