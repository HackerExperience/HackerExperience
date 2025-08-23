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
      new_proc_s1_1 = Svc.Process.fetch!(server_1.id, by_id: proc_s1_1.id)
      new_proc_s1_2 = Svc.Process.fetch!(server_1.id, by_id: proc_s1_2.id)

      # The processes had no allocation/processed resources right after creation
      refute proc_s1_1.resources.allocated
      refute proc_s1_1.resources.processed
      refute proc_s1_2.resources.allocated
      refute proc_s1_2.resources.processed

      # The processes have the new resources set correctly in the database
      assert_decimal_eq(new_proc_s1_1.resources.allocated.cpu, Decimal.new(100_000))
      assert Resources.equal?(new_proc_s1_1.resources.processed, Resources.initial())
      assert_decimal_eq(new_proc_s1_2.resources.allocated.cpu, Decimal.new(100_000))
      assert Resources.equal?(new_proc_s1_2.resources.processed, Resources.initial())

      # The processes have the status changed from `awaiting_allocation` to `running`
      assert proc_s1_1.status == :awaiting_allocation
      assert proc_s1_1.status == :awaiting_allocation
      assert new_proc_s1_1.status == :running
      assert new_proc_s1_2.status == :running

      # Each had its completion date estimated correctly: 100ms and 200ms from the creation date
      assert_in_delta new_proc_s1_1.estimated_completion_ts,
                      new_proc_s1_1.last_checkpoint_ts + 100,
                      25

      assert_in_delta new_proc_s1_2.estimated_completion_ts,
                      new_proc_s1_2.last_checkpoint_ts + 200,
                      25

      # Now for Server 2. It has 200k/s cpu, with the only process having a 10k target: ~50ms
      {top_2_next_proc, _time_left, _timer_ref} = top_2.next

      # That's what happened: the "next" process is `proc_s2` (the only one)
      assert top_2_next_proc.id == proc_s2.id

      [new_proc_s2] = U.get_all_processes(server_2.id)

      # No resource allocation when it was originally created
      refute proc_s2.resources.allocated
      refute proc_s2.resources.processed

      # New process has the expected allocation (as well as `processed`) in DB: 100% of the CPU!
      assert_decimal_eq(new_proc_s2.resources.allocated.cpu, Decimal.new(200_000))
      assert Resources.equal?(new_proc_s2.resources.processed, Resources.initial())

      # It has the correct status flags
      assert proc_s2.status == :awaiting_allocation
      assert new_proc_s2.status == :running

      # Completion was estimated ~50ms after the creation date
      assert_in_delta new_proc_s2.estimated_completion_ts, new_proc_s2.last_checkpoint_ts + 50, 10

      # All 3 processes can be found in the ProcessRegistry
      assert [_, _, _] = U.get_all_process_registries()

      # Now we'll wait for the processes to complete
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
      assert_in_delta top_1_next_time_left, 50, 20

      # The previous process (`proc_s1_1`) does not exist in the database anymore. It's gone
      refute Svc.Process.fetch(server_1.id, by_id: proc_s1_1.id)

      # `proc_s1_2` has a different allocation
      new_proc_s1_2 = Svc.Process.fetch!(server_1.id, by_id: proc_s1_2.id)

      # It is now using 100% of the available CPU in the server (as opposed to 50% before)
      assert_decimal_eq(new_proc_s1_2.resources.allocated.cpu, Decimal.new(200_000))

      # It has a new checkpoint (which happened after our `adhoc_checkpoint`)
      assert new_proc_s1_2.last_checkpoint_ts >= adhoc_checkpoint

      # It has a new completion date (which is roughly ~50ms after the checkpoint)
      assert_in_delta new_proc_s1_2.estimated_completion_ts,
                      new_proc_s1_2.last_checkpoint_ts + 50,
                      25

      # It has some amount of processed resources (roughly around 10k or 50% of target)
      # PS: Do note it may be more than that because we wait an extra 10ms to make *sure* the
      # process is *really* complete. The oversized threshold is to avoid flakes in slower CI
      refute Resources.equal?(new_proc_s1_2.resources.processed, Resources.initial())
      assert_decimal_eq(new_proc_s1_2.resources.processed.cpu, 11_000, 3_000)

      # As for `server_2`, the only process it was working on is complete and now the TOP is empty
      top_2_pid = fetch_top_pid!(server_2.id, ctx)
      top_2 = :sys.get_state(top_2_pid)
      refute top_2.next

      # The previous process (`proc_s2`) is gone
      refute Svc.Process.fetch(server_2.id, by_id: proc_s2.id)

      # The completed processes are gone from the ProcessRegistry
      assert [proc_in_registry] = U.get_all_process_registries()

      # The only process in registry is `proc_s1_2`, which is the only one running at this point
      assert proc_in_registry.server_id == server_1.id
      assert proc_in_registry.process_id == proc_s1_2.id

      # If we wait an extra ~50ms, `proc_s1_2` should be completed too
      assert [_process_completed_event] = wait_process_completed_event!(proc_s1_2)

      # No "next" process for TOP at `server_1`
      top_1_pid = fetch_top_pid!(server_1.id, ctx)
      top_1 = :sys.get_state(top_1_pid)
      refute top_1.next

      # Process is gone from the database
      refute Svc.Process.fetch(server_1.id, by_id: proc_s1_2.id)

      # Nothing left in the Registry
      assert [] = U.get_all_process_registries()

      # Server 1 had its TOP recalculated three times
      assert [_, _, _] = wait_events_on_server!(server_1.id, :top_recalcado, 3)

      # Server 2, twice
      assert [_, _] = wait_events_on_server!(server_2.id, :top_recalcado, 2)
    end
  end

  describe "allocation" do
    test "when the 'next' process changes, the previous 'next' timer is deleted", ctx do
      %{server: server, entity: entity} = Setup.server()
      proc_1 = Setup.process!(server.id, objective: %{cpu: 100_000})
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)

      # `proc_1` is naturally the "next" proc, since it's the only one in the server
      assert elem(state.next, 0).id == proc_1.id
      proc_1_timer = elem(state.next, 2)

      # Now we'll add another process that is considerably faster
      spec = Setup.process_spec(server.id, entity.id)
      assert {:ok, proc_2} = U.Process.execute(spec)

      # TOP has changed to set `proc_2` as "next"
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_2.id

      # The previous timer is dead (it no longer applies)
      assert false == Elixir.Process.cancel_timer(proc_1_timer)
    end
  end

  describe "over-allocation / resources overflow" do
    test "overflow when process is created (with empty TOP)", ctx do
      %{server: server, entity: entity} = Setup.server(resources: %{cpu: 500, ram: 1})
      DB.commit()

      spec = Setup.process_spec(server.id, entity.id)
      assert {:error, :overflow} = U.Process.execute(spec)

      # TOP is mostly unchanged (next == nil)
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      refute state.next
    end

    test "overflow when process is created (with other running processes)", ctx do
      %{server: server, entity: entity} = Setup.server(resources: %{cpu: 100, ram: 30})
      proc_1 = Setup.process!(server.id, static: %{ram: 10})
      proc_2 = Setup.process!(server.id, static: %{ram: 10})
      DB.commit()

      # TOP is running and the two processes above have been alocated resources
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state_before = :sys.get_state(pid)

      # Now we'll add a process that overflows the available resources
      spec = Setup.process_spec(server.id, entity.id)
      assert {:error, :overflow} = U.Process.execute(spec)

      # TOP still has the same process as "next" target (and same timer)
      state_after = :sys.get_state(pid)
      assert elem(state_before.next, 0).id == elem(state_after.next, 0).id
      assert elem(state_before.next, 2) == elem(state_after.next, 2)

      # There are still (and only) two ongoing processes
      Core.with_context(:server, server.id, :read, fn ->
        assert [_, _] = DB.all(Process)
      end)

      assert [process_killed_event] = wait_events_on_server!(server.id, :process_killed)
      # The process that was killed is not `proc_1` or `proc_2`, but rather the new one that we
      # attempted to execute. We don't have access to its ID within this test, though
      assert process_killed_event.data.process.id not in [proc_1.id, proc_2.id]
      assert process_killed_event.data.reason == :killed
    end

    test "overflow when server resources go down (affecting multiple processes)", ctx do
      # Initially the Server has sufficient RAM for all four processes
      server = Setup.server!(resources: %{cpu: 100, ram: 70})
      proc_1 = Setup.process!(server.id, static: %{ram: 30}, objective: %{cpu: 250})
      proc_2 = Setup.process!(server.id, static: %{ram: 20}, objective: %{cpu: 100})
      _proc_3 = Setup.process!(server.id, static: %{ram: 10}, objective: %{cpu: 5_000})
      proc_4 = Setup.process!(server.id, static: %{ram: 10}, objective: %{cpu: 90})
      DB.commit()

      # Run and wait for first allocation
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)

      # With all 4 processes running, `proc_4` is the "next" to complete given smaller objective
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_4.id
      timer_proc_4 = elem(state.next, 2)

      # We still have four processes (none were dropped so far)
      Core.with_context(:server, server.id, :read, fn ->
        assert [_, _, _, _] = DB.all(Process)
      end)

      # Now we'll update the server resources
      # The newest process (proc_4) will be dropped after this. The new total allocated RAM is 60
      U.Server.update_resources(server.id, %{ram: 60})
      assert :ok == TOP.on_server_resources_changed(server.id)

      # With `proc_4` gone, the "next" target is now `proc_2`
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_2.id
      timer_proc_2 = elem(state.next, 2)

      # The timer that was tracking `proc_4`'s conclusion has been killed
      assert false == Elixir.Process.cancel_timer(timer_proc_4)

      # There are only 3 proceseses now; `proc_4` is gone
      assert [_, _, _] = U.get_all_processes(server.id)
      refute Svc.Process.fetch(server.id, by_id: proc_4.id)

      # Let's change the resources once again, now to 35. `proc_3` and `proc_2` should be killed
      U.Server.update_resources(server.id, %{ram: 35})
      assert :ok == TOP.on_server_resources_changed(server.id)

      # Now obviously `proc_1` is the "next" process, since it's the only one left
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_1.id
      timer_proc_1 = elem(state.next, 2)

      # The timer that was tracking `proc_2`'s conclusion has been killed
      assert false == Elixir.Process.cancel_timer(timer_proc_2)

      # Only `proc_1` is remaining now
      assert [remaining_process] = U.get_all_processes(server.id)
      assert remaining_process.id == proc_1.id

      # And now let's change it to 29. There won't be any processes left
      U.Server.update_resources(server.id, %{ram: 29})
      assert :ok == TOP.on_server_resources_changed(server.id)
      state = :sys.get_state(pid)
      refute state.next

      # The timer that was tracking `proc_1`'s conclusion has been killed
      assert false == Elixir.Process.cancel_timer(timer_proc_1)
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
      assert wait_events_on_server!(server.id, :process_completed, 3)

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

      # Wait for process to be completed
      assert wait_events_on_server!(server.id, :process_completed)

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
        # Wait 15ms (for Registry to be updated and return the new TOP pid)
        :timer.sleep(15)

        # Grab the pid for the "current" TOP
        pid = fetch_top_pid!(server.id, ctx)
        top = :sys.get_state(pid)

        cond do
          is_nil(top.next) ->
            # The process was completed, despite each TOP never running for more than 10ms
            {:halt, :ok}

          i == 10 ->
            flunk("TOP never completed the process: #{inspect(:sys.get_state(pid))}")

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
      [process_after] = U.get_all_processes(server.id)
      assert process_after.id == process_before.id

      # Initially, the process had no resources allocated. Now it does
      refute process_before.resources.allocated
      assert process_after.resources.allocated

      # Similarly, it has a "last checkpoint time" as well as an estimated completion date
      assert process_after.last_checkpoint_ts
      assert process_after.estimated_completion_ts

      # Its "processed" resource is set to zero (nothing has been processed yet)
      assert Resources.equal?(process_after.resources.processed, Resources.initial())
    end
  end

  describe "pause/1" do
    test "pauses a running process", ctx do
      server = Setup.server!(resources: %{cpu: 1_000})
      proc_1 = Setup.process!(server.id, %{objective: %{cpu: 1000}})
      proc_2 = Setup.process!(server.id, %{objective: %{cpu: 500}})
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)

      new_proc_1 = Svc.Process.fetch!(server.id, by_id: proc_1.id)
      new_proc_2 = Svc.Process.fetch!(server.id, by_id: proc_2.id)

      # Both processes are running
      assert new_proc_1.status == :running
      assert new_proc_2.status == :running

      # Both processes received 50% of the dynamic allocation
      assert_decimal_eq(new_proc_1.resources.allocated.cpu, 500)
      assert_decimal_eq(new_proc_2.resources.allocated.cpu, 500)

      # Despite both processes receiving 50% of the server resources, `proc_2` is clearly the first
      # one to complete because it requires half of the `objective`
      assert elem(state.next, 0).id == proc_2.id
      proc_2_timer = elem(state.next, 2)

      # Now we'll pause `new_proc_2`
      assert {:ok, new_proc_2} = TOP.pause(new_proc_2)
      assert new_proc_2.id == proc_2.id
      assert new_proc_2.status == :paused

      # Many things should happen once we paused, including:
      state = :sys.get_state(pid)

      # 1. The "next" process to complete is `proc_1` (`proc_2` will never complete while paused)
      assert elem(state.next, 0).id == proc_1.id

      # 2. The `proc_2_timer` is dead
      assert false == Elixir.Process.cancel_timer(proc_2_timer)

      # 3. The processes have the correct `allocated` and `status` values in the database
      new_proc_1 = Svc.Process.fetch!(server.id, by_id: proc_1.id)
      new_proc_2 = Svc.Process.fetch!(server.id, by_id: proc_2.id)

      # `proc_1` is running and using 100% of the dynamic server resources
      assert_decimal_eq(new_proc_1.resources.allocated.cpu, 1000)
      assert new_proc_1.status == :running

      # `proc_2` is using 0% of the dynamic server resources
      assert_decimal_eq(new_proc_2.resources.allocated.cpu, 0)
      assert new_proc_2.status == :paused

      # `proc_2` will never complete (as long as it's paused)
      refute new_proc_2.estimated_completion_ts

      # `proc_2` is using the "paused" static resources
      proc_2_paused_resources = new_proc_2.resources.static.paused |> Resources.from_map()
      assert Resources.equal?(new_proc_2.resources.allocated, proc_2_paused_resources)

      # 4. The ProcessPausedEvent is emitted
      assert [process_resumed_event] = wait_events_on_server!(server.id, :process_paused)
      assert process_resumed_event.data.process.id == proc_2.id
    end

    @tag capture_log: true
    test "can't pause an already paused process", ctx do
      server = Setup.server!()
      process = Setup.process!(server.id)
      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      assert state.next

      # We'll pause the (only) process in this TOP
      process = Svc.Process.fetch!(server.id, by_id: process.id)
      assert {:ok, _} = TOP.pause(process)

      # Naturally there won't be any "next" for this TOP
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      refute state.next

      # Can't pause a paused process
      process = Svc.Process.fetch!(server.id, by_id: process.id)
      assert {:error, {:cant_pause, :paused}} == TOP.pause(process)
    end
  end

  describe "resume/1" do
    test "resumes a paused process", ctx do
      server = Setup.server!(resources: %{cpu: 1_000})
      proc_1 = Setup.process!(server.id, %{objective: %{cpu: 1000}})
      proc_2 = Setup.process!(server.id, %{objective: %{cpu: 500}})
      DB.commit()

      # We have two running processes, with `proc_2` being the "next"
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_2.id

      # Let's pause `proc_2`
      proc_2 = Svc.Process.fetch!(server.id, by_id: proc_2.id)
      assert {:ok, proc_2} = TOP.pause(proc_2)
      assert proc_2.status == :paused

      # Naturally `proc_1` is the "next" now
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_1.id
      proc_1_timer = elem(state.next, 2)

      # Let's resume `proc_2`
      assert {:ok, proc_2} = TOP.resume(proc_2)
      assert proc_2.status == :running

      # `proc_2` is back as "next" target for the TOP
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_2.id

      # The old `proc_1_timer` was canceled
      assert false == Elixir.Process.cancel_timer(proc_1_timer)

      # The allocation is as expected (50% for each process)
      new_proc_1 = Svc.Process.fetch!(server.id, by_id: proc_1.id)
      new_proc_2 = Svc.Process.fetch!(server.id, by_id: proc_2.id)

      # Both processes are running
      assert new_proc_1.status == :running
      assert new_proc_2.status == :running

      # Both processes received 50% of the dynamic allocation
      assert_decimal_eq(new_proc_1.resources.allocated.cpu, 500)
      assert_decimal_eq(new_proc_2.resources.allocated.cpu, 500)

      # Emits the ProcessResumedEvent
      assert [process_resumed_event] = wait_events_on_server!(server.id, :process_resumed)
      assert process_resumed_event.data.process.id == proc_2.id
    end

    @tag capture_log: true
    test "can't resume a non-paused process", ctx do
      server = Setup.server!()
      process = Setup.process!(server.id)
      DB.commit()

      assert {:error, {:cant_resume, :awaiting_allocation}} = TOP.resume(process)

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})

      process = Svc.Process.fetch!(server.id, by_id: process.id)
      assert {:error, {:cant_resume, :running}} = TOP.resume(process)
    end

    test "can't resume a process for which the server no longer has sufficient resources", ctx do
      # Scenario: the static allocation for paused process is smaller than for a running process.
      # The server had plenty of RAM when the process started, but after it was paused another
      # process started running, occupying the remaining resources in the server. When the process
      # is resumed, it needs more resources but the server can't handle it. The obvious solution
      # is to undo the resume (instead of the default "drop the newest process" heuristic).
      server = Setup.server!(resources: %{ram: 20})
      proc_1 = Setup.process!(server.id, static: %{paused: %{ram: 10}, running: %{ram: 20}})
      DB.commit()

      # `proc_1` is running and using 20MB of RAM (100% of server's available RAM)
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_1.id

      proc_1 = Svc.Process.fetch!(server.id, by_id: proc_1.id)

      # Let's pause proc_1.
      assert {:ok, proc_1} = TOP.pause(proc_1)
      state = :sys.get_state(pid)
      refute state.next

      # `proc_1` is now using only 10MB of RAM
      assert_decimal_eq(proc_1.resources.allocated.ram, 10)

      # Now we add `proc_2` and `proc_3`, which use 7MB and 2MB respectively
      Core.begin_context(:universe, :write)
      proc_2 = Setup.process!(server.id, static: %{ram: 7})
      proc_3 = Setup.process!(server.id, static: %{ram: 2})
      DB.commit()

      # Re-start the TOP for easy re-scheduling
      Elixir.Process.exit(pid, :kill)
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)

      # The "next" is anything but `proc_1`
      refute elem(state.next, 0).id == proc_1.id

      # Let's just make sure everything looks alright in the database
      # There are 3 processes
      assert [_, _, _] = U.get_all_processes(server.id)

      proc_1 = Svc.Process.fetch!(server.id, by_id: proc_1.id)
      proc_2 = Svc.Process.fetch!(server.id, by_id: proc_2.id)
      proc_3 = Svc.Process.fetch!(server.id, by_id: proc_3.id)

      # `proc_1` is paused and the other two are running
      assert proc_1.status == :paused
      assert proc_2.status == :running
      assert proc_3.status == :running

      # Let's resume `proc_1`. It should fail
      assert {:error, :overflow} = TOP.resume(proc_1)

      # Even if we try to resume it multiple times, it should keep failing
      assert {:error, :overflow} = TOP.resume(proc_1)
      assert {:error, :overflow} = TOP.resume(proc_1)
      assert {:error, :overflow} = TOP.resume(proc_1)

      # The ProcessResumedEvent was never emitted
      refute_events_on_server!(server.id, :process_resumed)
    end
  end

  describe "renice/2" do
    test "changes the priority of the process", ctx do
      %{server: server, entity: entity_1} = Setup.server(resources: %{cpu: 1000})
      entity_2 = Setup.entity!()

      proc_e1_1 = Setup.process!(server.id, entity_id: entity_1.id, priority: 9)
      proc_e1_2 = Setup.process!(server.id, entity_id: entity_1.id, priority: 1)
      proc_e2 = Setup.process!(server.id, entity_id: entity_2.id, priority: 99)
      DB.commit()

      # TOP started and `proc_e2` is the "next"
      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})
      pid = fetch_top_pid!(server.id, ctx)
      state = :sys.get_state(pid)
      assert elem(state.next, 0).id == proc_e2.id

      # For context, here's the expected initial allocation:
      proc_e1_1 = Svc.Process.fetch!(server.id, by_id: proc_e1_1.id)
      proc_e1_2 = Svc.Process.fetch!(server.id, by_id: proc_e1_2.id)
      proc_e2 = Svc.Process.fetch!(server.id, by_id: proc_e2.id)

      # `entity_1` has access to 50% of the resources (500MHz). In a total of 9 + 1 = 10 shares,
      # that's 50MHz per share. `entity_2` has access to a total of 500MHz. Expected allocation:
      assert_decimal_eq(proc_e1_1.resources.allocated.cpu, 9 * 50)
      assert_decimal_eq(proc_e1_2.resources.allocated.cpu, 1 * 50)
      assert_decimal_eq(proc_e2.resources.allocated.cpu, 500)

      # Let's change the priority of `proc_e1_2` to be 11
      assert {:ok, _} = TOP.renice(proc_e1_2, 11)

      proc_e1_1 = Svc.Process.fetch!(server.id, by_id: proc_e1_1.id)
      proc_e1_2 = Svc.Process.fetch!(server.id, by_id: proc_e1_2.id)
      proc_e2 = Svc.Process.fetch!(server.id, by_id: proc_e2.id)

      # Now `entity_1` has a total of 9 + 11 = 20 shares, which means 500 / 20 = 25mhz/share
      assert_decimal_eq(proc_e1_1.resources.allocated.cpu, 9 * 25)
      assert_decimal_eq(proc_e1_2.resources.allocated.cpu, 11 * 25)

      # Process from `entity_2` remains unchanged
      assert_decimal_eq(proc_e2.resources.allocated.cpu, 500)

      # A ProcessRenicedEvent was emitted
      assert [event] = wait_events_on_server!(server.id, :process_reniced)
      assert event.data.process.id == proc_e1_2.id
    end
  end

  describe "signal/3" do
    test "delivers a signal to the process" do
      %{server: server} = Setup.server()
      %{process: process} = Setup.process(server.id, type: :file_install)
      DB.commit()

      # Sending a SIG_TGT_FILE_DELETED to a FileInstallProcess performs a noop since it's irrelevant
      # for that particular process
      assert {:ok, :noop} = TOP.signal(process, :sig_tgt_file_deleted)

      # When we send a SIG_SRC_FILE_DELETED to a FileInstallProcess, it gets deleted
      assert {:ok, :delete} = TOP.signal(process, :sig_src_file_deleted)

      # Indeed, we can see it no longer exists
      Core.with_context(:server, server.id, :read, fn ->
        assert [] = DB.all(Process)
      end)

      # And neither does the Registry
      Core.with_context(:universe, :read, fn ->
        assert [] = DB.all(ProcessRegistry)
      end)

      # A ProcessKilledEvent was emitted
      assert [process_killed_event] = wait_events_on_server!(server.id, :process_killed)
      assert process_killed_event.name == :process_killed
      assert process_killed_event.data.process.id == process.id

      # We got two TopRecalcadoEvents, one for the Boot (because it allocated the Process we just
      # created) and another one for the killing
      top_recalcado_events = wait_events_on_server!(server.id, :top_recalcado, 2)
      assert Enum.find(top_recalcado_events, &(&1.data.reason == :boot))
      assert Enum.find(top_recalcado_events, &(&1.data.reason == {:killed, process.id}))
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
