defmodule Game.Process.TOPTest do
  use Test.DBCase, async: true

  alias Game.Process.{Resources, TOP}
  alias Game.{Process, ProcessRegistry}

  setup [:with_game_db]

  describe "on_boot/1" do
    test "instantiates a TOP for each server with active processes (full lifecycle)", ctx do
      # Server 1 has two processes
      server_1 = Setup.server!(resources: %{cpu: 200_000})
      proc_s1_1 = Setup.process!(server_1.id, objective: %{cpu: 10_000})
      proc_s1_2 = Setup.process!(server_1.id, objective: %{cpu: 20_000})

      # Server 2 has one process
      server_2 = Setup.server!(resources: %{cpu: 200_000})
      proc_s2 = Setup.process!(server_2.id, objective: %{cpu: 10_000})

      # Server 3 has no active processes. It should never show up in this test
      server_3 = Setup.server!()
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})

      # Get the PID for the running TOPs
      top_1_pid = fetch_top_pid!(server_1.id, ctx)
      top_1 = :sys.get_state(top_1_pid)
      assert top_1.server_id == server_1.id

      top_2_pid = fetch_top_pid!(server_2.id, ctx)
      top_2 = :sys.get_state(top_2_pid)
      assert top_2.server_id == server_2.id

      # There is no running TOP for server 3 (because it has no processes)
      reject_top_pid!(server_3.id, ctx)

      # Server 1 has 200k/s cpu, with procs objective being 10k and 20k. Each process will be
      # allocated 100k/s, meaning it would take 0.1s and 0.2s respectively to finish each process
      {top_1_next_proc, _time_left, _timer_ref} = top_1.next

      # Indeed, that's exactly what we see here: next process is `proc_s1_1`
      assert top_1_next_proc.id == proc_s1_1.id

      # We can see that proc_s1_1 and proc_s1_2 have been correctly allocated resources in DB
      Core.with_context(:server, server_1.id, :read, fn ->
        new_proc_s1_1 = Svc.Process.fetch!(by_id: proc_s1_1.id)
        new_proc_s1_2 = Svc.Process.fetch!(by_id: proc_s1_2.id)

        # The processes had no allocation/processed resources right after creation
        refute proc_s1_1.resources.allocated
        refute proc_s1_1.resources.processed
        refute proc_s1_2.resources.allocated
        refute proc_s1_2.resources.processed

        # The processes have the new resources set correctly in the database
        assert new_proc_s1_1.resources.allocated.cpu == Decimal.new(100_000)
        assert Resources.equal?(new_proc_s1_1.resources.processed, Resources.initial())
        assert new_proc_s1_2.resources.allocated.cpu == Decimal.new(100_000)
        assert Resources.equal?(new_proc_s1_2.resources.processed, Resources.initial())

        # Each had its completion date estimated correctly: 100ms and 200ms from the creation date
        assert_in_delta new_proc_s1_1.estimated_completion_ts,
                        new_proc_s1_1.last_checkpoint_ts + 100,
                        10

        assert_in_delta new_proc_s1_2.estimated_completion_ts,
                        new_proc_s1_2.last_checkpoint_ts + 200,
                        10
      end)

      # Now for Server 2. It has 200k/s cpu, with the only process having a 10k target: ~50ms
      {top_2_next_proc, _time_left, _timer_ref} = top_2.next

      # That's what happened: the "next" process is `proc_s2` (the only one)
      assert top_2_next_proc.id == proc_s2.id

      Core.with_context(:server, server_2.id, :read, fn ->
        [new_proc_s2] = DB.all(Process)

        # No resource allocation when it was originally created
        refute proc_s2.resources.allocated
        refute proc_s2.resources.processed

        # New process has the expected allocation (as well as `processed`) in DB: 100% of the CPU!
        assert new_proc_s2.resources.allocated.cpu == Decimal.new(200_000)
        assert Resources.equal?(new_proc_s2.resources.processed, Resources.initial())

        # Completion was estimated ~50ms after the creation date
        assert_in_delta new_proc_s2.estimated_completion_ts, new_proc_s2.last_checkpoint_ts + 50, 10
      end)

      # All 3 processes can be found in the ProcessRegistry
      Core.with_context(:universe, :read, fn ->
        assert [_, _, _] = DB.all(ProcessRegistry)
      end)

      # Now we'll sleep for ~100ms. By then, `proc_s1_1` and `proc_s2` should be completed
      adhoc_checkpoint = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      # When the processes hit their target (in ~100ms), TOP emitted the ProcessCompletedEvent
      assert [proc_s1_1_completed_event] = wait_process_completed_event!(proc_s1_1)
      assert [proc_s2_completed_event] = wait_process_completed_event!(proc_s2)

      assert proc_s1_1_completed_event.name == :process_completed
      assert proc_s1_1_completed_event.data.process.id == proc_s1_1.id

      assert proc_s2_completed_event.name == :process_completed
      assert proc_s2_completed_event.data.process.id == proc_s2.id

      # Now the next process to be completed in server_1 is `proc_s1_2`
      top_1_pid = fetch_top_pid!(server_1.id, ctx)
      top_1 = :sys.get_state(top_1_pid)
      assert {top_1_next_proc, top_1_next_time_left, _} = top_1.next
      assert top_1_next_proc.id == proc_s1_2.id

      # `proc_s1_2` is expected to complete in 50ms. Why? Because now it has the full 200k/s, so the
      # remaining 10k target will take only 50ms. It is 50% processed but the new allocation has
      # higher rate, so instead of "100ms + 100ms" it will take "100ms + 50ms" to reach the target
      assert_in_delta top_1_next_time_left, 50, 10

      Core.with_context(:server, server_1.id, :read, fn ->
        # The previous process (`proc_s1_1`) does not exist in the database anymore. It's gone
        refute Svc.Process.fetch(by_id: proc_s1_1.id)

        # `proc_s1_2` has a different allocation
        assert new_proc_s1_2 = Svc.Process.fetch!(by_id: proc_s1_2.id)

        # It is now using 100% of the available CPU in the server (as opposed to 50% before)
        assert new_proc_s1_2.resources.allocated.cpu == Decimal.new(200_000)

        # It has a new checkpoint (which happened after our `adhoc_checkpoint`)
        assert new_proc_s1_2.last_checkpoint_ts >= adhoc_checkpoint

        # It has a new completion date (which is roughly ~50ms after the checkpoint)
        assert_in_delta new_proc_s1_2.estimated_completion_ts,
                        new_proc_s1_2.last_checkpoint_ts + 50,
                        10

        # It has some amount of processed resources (roughly around 10k or 50% of target)
        # PS: Do note it may be more than that because we wait an extra 10ms to make *sure* the
        # process is *really* complete
        refute Resources.equal?(new_proc_s1_2.resources.processed, Resources.initial())
        assert :eq == Decimal.compare(new_proc_s1_2.resources.processed.cpu, 11_000, 1000)
      end)

      # As for `server_2`, the only process it was working on is complete and now the TOP is empty
      top_2_pid = fetch_top_pid!(server_2.id, ctx)
      top_2 = :sys.get_state(top_2_pid)
      refute top_2.next

      Core.with_context(:server, server_2.id, :read, fn ->
        # The previous process (`proc_s2`) is gone
        refute Svc.Process.fetch(by_id: proc_s2.id)
      end)

      # The completed processes are gone from the ProcessRegistry
      Core.with_context(:universe, :read, fn ->
        assert [proc_in_registry] = DB.all(ProcessRegistry)
        # The only process in registry is `proc_s1_2`, which is the only one running at this point
        assert proc_in_registry.server_id == server_1.id
        assert proc_in_registry.process_id == proc_s1_2.id
      end)

      # If we wait an extra ~50ms, `proc_s1_2` should be completed too
      assert [_process_completed_event] = wait_process_completed_event!(proc_s1_2)

      # No "next" process for TOP at `server_1`
      top_1_pid = fetch_top_pid!(server_1.id, ctx)
      top_1 = :sys.get_state(top_1_pid)
      refute top_1.next

      # Process is gone from the database
      Core.with_context(:server, server_1.id, :read, fn ->
        refute Svc.Process.fetch(by_id: proc_s1_2.id)
      end)

      # Nothing left in the Registry
      Core.with_context(:universe, :read, fn ->
        assert [] = DB.all(ProcessRegistry)
      end)

      # Server 1 had its TOP recalculated two times (when the first process completed and when the
      # second process completed -- the boot recalculation did not trigger the event because no
      # process had changed prior to that)
      [_, _] = wait_events_on_server!(server_1.id, :top_recalcado, 2)

      # Server 2, once (when its only process completed)
      [_] = wait_events_on_server!(server_2.id, :top_recalcado, 1)
    end
  end

  describe "allocation/scheduling edge cases" do
    test "multiple processes are completed when the TOP runs", ctx do
      # This could happen, for example, if the (actual) game server stays offline for some time
      # while in-game processes are still "running"
      server = Setup.server!()

      # Server has three completed processes
      _proc_1 = Setup.process!(server.id, completed: true)
      _proc_2 = Setup.process!(server.id, completed: true)
      _proc_3 = Setup.process!(server.id, completed: true)
      DB.commit()

      # Before the TOP runs, we have 3 processes total
      Core.with_context(:universe, :read, fn ->
        assert [_, _, _] = DB.all(ProcessRegistry)
      end)

      # Run TOP for this server
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)

      # After some time has passed, all three processes are gone
      :timer.sleep(100)

      Core.with_context(:universe, :read, fn ->
        assert [] = DB.all(ProcessRegistry)
      end)

      Core.with_context(:server, server.id, :read, fn ->
        assert [] = DB.all(Process)
      end)

      # And the TOP's "next" process is `nil`
      top = :sys.get_state(pid)
      refute top.next
    end

    @tag capture_log: true
    test "'next' process didn't reach objective when TOP originally thought it would", ctx do
      # I don't see how this scenario is ever possible, but I'd like to have a test case to make
      # sure the system can handle "impossible" scenarios too (for robustness sake)
      server = Setup.server!(resources: %{cpu: 1_000})
      Setup.process!(server.id, %{objective: %{cpu: 100}})
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)

      # With an objective of 100 and an allocation of 1000/s, the process would complete in ~100ms
      top = :sys.get_state(pid)
      assert top.next

      # Monitor the TOP (Erlang) process so we can hear it scream
      Elixir.Process.monitor(pid)
      Elixir.Process.flag(:trap_exit, true)

      # However, we will send the `:next_process_completed` timer signal NOW!
      Elixir.Process.send(pid, :next_process_completed, [])

      # This will result in the TOP realizing something is wrong and crashing itself
      assert_receive {:DOWN, _, _, pid, :wrong_schedule}, 100
      refute Elixir.Process.alive?(pid)

      :timer.sleep(20)

      # A brand new TOP will start again
      pid_2 = fetch_top_pid!(server.id, ctx)
      refute pid_2 == pid

      # Give ample time for the process to complete
      :timer.sleep(100)

      # And now the process is gone
      top = :sys.get_state(pid_2)
      refute top.next
    end

    test "a process can reach conclusion in an always-crashing TOP", ctx do
      # Scenario: for some reason, the TOP crashes constantly (say, every 10ms). Eventually the
      # process inside it should reach conclusion *as long as it's been allocated once*
      server = Setup.server!(resources: %{cpu: 1_000})
      Setup.process!(server.id, %{objective: %{cpu: 50}})
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      top = :sys.get_state(pid)
      assert top.next

      # The process received its initial allocation (in the DB):
      Core.with_context(:server, server.id, :read, fn ->
        assert [new_process] = DB.all(Process)
        assert new_process.resources.allocated
      end)

      Enum.reduce_while(1..10, 0, fn i, _ ->
        # Wait 10s (for Registry to be updated and return the new TOP pid)
        :timer.sleep(10)

        # Grab the pid for the "current" TOP
        pid = fetch_top_pid!(server.id, ctx)
        top = :sys.get_state(pid)

        cond do
          is_nil(top.next) ->
            # The process was completed, despite each TOP never running for more than 10ms
            {:halt, :ok}

          i == 10 ->
            flunk("TOP never completed the process")

          true ->
            # Force-kill the TOP GenServer
            Elixir.Process.exit(pid, :something_bad_happened)
            refute Elixir.Process.alive?(pid)
            {:cont, i + 1}
        end
      end)

      # TOP is still running, but the process is gone (completed)
      pid = fetch_top_pid!(server.id, ctx)
      top = :sys.get_state(pid)
      refute top.next
    end
  end

  describe "bootstrap" do
    test "schedules processes after boot", ctx do
      %{server: server, meta: meta} = Setup.server()
      process_before = Setup.process!(server.id)

      assert {:ok, pid} = TOP.start_link({server.id, ctx.db_context, ctx.shard_id})

      state = :sys.get_state(pid)

      # Server resources were loaded
      assert state.server_resources == meta.resources

      # "Next" process was scheduled
      assert {next_process, _, _} = state.next
      assert next_process.id == process_before.id

      # The process was allocated some resources and a completion estimate
      Core.with_context(:server, server.id, :read, fn ->
        [process_after] = DB.all(Process)
        assert process_after.id == process_before.id

        # Initially, the process had no resources allocated. Now it does
        refute process_before.resources.allocated
        assert process_after.resources.allocated

        # Similarly, it has a "last checkpoint time" as well as an estimated completion date
        assert process_after.last_checkpoint_ts
        assert process_after.estimated_completion_ts

        # Its "processed" resource is set to zero (nothing has been processed yet)
        assert Resources.equal?(process_after.resources.processed, Resources.initial())
      end)
    end
  end

  defp fetch_top_pid!(server_id, %{db_context: db_context, shard_id: shard_id}) do
    [{pid, _}] = Registry.lookup(TOP.Registry.name(), {server_id.id, db_context, shard_id})
    pid
  end

  # Use this to assert that a TOP is not running
  defp reject_top_pid!(server_id, %{db_context: db_context, shard_id: shard_id}),
    do: [] = Registry.lookup(TOP.Registry.name(), {server_id.id, db_context, shard_id})
end
