defmodule Game.Process.TOPTest do
  use Test.DBCase, async: true

  alias Game.Process.{TOP}
  alias Game.Process

  setup [:with_game_db]

  describe "on_boot/1" do
    test "instantiates a TOP for each server with active processes", ctx do
      server_1 = Setup.server!()
      server_2 = Setup.server!()

      # Server 1 has two processes
      _proc_s1_1 = Setup.process!(server_1.id)
      _proc_s1_2 = Setup.process!(server_1.id)

      # Server 2 has one process
      _proc_s2_1 = Setup.process!(server_2.id)

      # Server 3 has no active processes
      Setup.server!()

      DB.commit()

      assert :ok == TOP.on_boot({ctx.db_context, ctx.shard_id})

      # If we query the TOP Supervisor, we'll find out there exists two TOPs being supervised
      assert [{_, pid_1, :worker, [TOP]}, {_, pid_2, :worker, [TOP]}] =
               DynamicSupervisor.which_children(TOP.Supervisor)

      state_pid_1 = :sys.get_state(pid_1)
      state_pid_2 = :sys.get_state(pid_2)

      top_1 = Enum.find([state_pid_1, state_pid_2], fn state -> state.server_id == server_1.id end)
      top_2 = Enum.find([state_pid_1, state_pid_2], fn state -> state.server_id == server_2.id end)

      assert top_1.server_id == server_1.id
      # assert Enum.count(top_1.processes) == 2

      assert top_2.server_id == server_2.id
      # assert Enum.count(top_2.processes) == 1
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

        # TODO: Resources.equal?()
        # # Its "processed" resource is set to zero (nothing has been processed yet)
        # assert process_after.resources.processed == Resources.initial()
      end)
    end
  end
end
