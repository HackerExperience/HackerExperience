defmodule Game.Process.TOPTest do
  use Test.DBCase, async: true

  alias Game.Process.TOP

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
      assert Enum.count(top_1.processes) == 2

      assert top_2.server_id == server_2.id
      assert Enum.count(top_2.processes) == 1
    end
  end

  describe "bootstrap" do
    test "schedules processes after boot", ctx do
      %{server: server} = Setup.server()

      assert {:ok, pid} = TOP.start_link({server.id, ctx.db_context, ctx.shard_id})

      assert %{processes: []} = :sys.get_state(pid)
    end
  end
end
