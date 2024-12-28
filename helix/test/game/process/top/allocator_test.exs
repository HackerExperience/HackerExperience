defmodule Game.Process.TOP.AllocatorTest do
  use Test.DBCase, async: true
  alias Game.Process.TOP.Allocator

  setup [:with_game_db]

  describe "allocate/3" do
    test "allocates resources accordingly" do
      server = Setup.server!()

      proc_1 = Setup.process!(server.id, objective: %{cpu: 1000})
      proc_2 = Setup.process!(server.id, objective: %{cpu: 1500})

      # TODO: This should come from a util
      server_resources =
        %{
          cpu: 2000,
          ram: 300
        }

      assert {:ok, allocated_processes} =
               Allocator.allocate(server.id, server_resources, [proc_1, proc_2])

      assert [{_, alloc_1}, {_, alloc_2}] = Enum.sort_by(allocated_processes, fn {p, _} -> p.id end)

      # Each process received half of the available CPU
      assert alloc_1.cpu == 1000
      assert alloc_2.cpu == 1000

      # Each process received the minimum static allocation
      assert alloc_1.ram == proc_1.resources.static.running.ram
      assert alloc_2.ram == proc_2.resources.static.running.ram
    end

    test "returns an error when server resources are insufficient" do
      server = Setup.server!()

      # Both servers need a minimum allocation of 250MB total
      proc_1 = Setup.process!(server.id, static: %{ram: 100})
      proc_2 = Setup.process!(server.id, static: %{ram: 150})

      # The server only has 200MB available
      server_resources = %{ram: 200}

      assert {:error, {:overflow, [:ram]}} =
               Allocator.allocate(server.id, server_resources, [proc_1, proc_2])
    end
  end
end
