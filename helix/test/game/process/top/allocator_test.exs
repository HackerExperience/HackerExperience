defmodule Game.Process.TOP.AllocatorTest do
  use Test.DBCase, async: true
  alias Game.Process.TOP.Allocator
  alias Game.Process.Resources

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
        |> Resources.from_map()

      assert {:ok, allocated_processes} = Allocator.allocate(server_resources, [proc_1, proc_2])

      assert [%{next_allocation: alloc_1}, %{next_allocation: alloc_2}] =
               Enum.sort_by(allocated_processes, fn p -> p.id end)

      # Each process received half of the available CPU
      assert_decimal_eq(alloc_1.cpu, Decimal.new(1000))
      assert_decimal_eq(alloc_2.cpu, Decimal.new(1000))

      # Each process received the minimum static allocation
      assert_decimal_eq(alloc_1.ram, proc_1.resources.static.running.ram)
      assert_decimal_eq(alloc_2.ram, proc_2.resources.static.running.ram)
    end

    test "splits shares among different entities (same priority)" do
      %{server: server, entity: entity_1, meta: %{resources: server_resources}} =
        Setup.server(resources: %{cpu: 1000})

      entity_2 = Setup.entity!()

      proc_e1_1 = Setup.process!(server.id, entity_id: entity_1.id)
      proc_e1_2 = Setup.process!(server.id, entity_id: entity_1.id)
      proc_e2 = Setup.process!(server.id, entity_id: entity_2.id)

      # `entity_1` has two processes
      assert proc_e1_1.entity_id == entity_1.id
      assert proc_e1_2.entity_id == entity_1.id

      # `entity_2` has one process
      assert proc_e2.entity_id == entity_2.id

      processes = [proc_e1_1, proc_e1_2, proc_e2]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_e1_1 = Enum.find(result, &(&1.id == proc_e1_1.id))
      proc_e1_2 = Enum.find(result, &(&1.id == proc_e1_2.id))
      proc_e2 = Enum.find(result, &(&1.id == proc_e2.id))

      # Processes from `entity_1` received 250 cpu each (50% of 50%)
      assert_decimal_eq(proc_e1_1.next_allocation.cpu, 250)
      assert_decimal_eq(proc_e1_2.next_allocation.cpu, 250)

      # Process from `entity_2` received 500 cpu (100% of 50%)
      assert_decimal_eq(proc_e2.next_allocation.cpu, 500)
    end

    test "splits shares among different entities (custom priorities)" do
      %{server: server, entity: entity_1, meta: %{resources: server_resources}} =
        Setup.server(resources: %{cpu: 1000})

      entity_2 = Setup.entity!()

      proc_e1_1 = Setup.process!(server.id, entity_id: entity_1.id, priority: 10)
      proc_e1_2 = Setup.process!(server.id, entity_id: entity_1.id, priority: 5)
      proc_e1_3 = Setup.process!(server.id, entity_id: entity_1.id, priority: 1)
      proc_e2 = Setup.process!(server.id, entity_id: entity_2.id, priority: 99)

      # `entity_1` has three processes
      assert proc_e1_1.entity_id == entity_1.id
      assert proc_e1_1.priority == 10
      assert proc_e1_2.entity_id == entity_1.id
      assert proc_e1_2.priority == 5
      assert proc_e1_3.entity_id == entity_1.id
      assert proc_e1_3.priority == 1

      # `entity_2` has one process
      assert proc_e2.entity_id == entity_2.id
      assert proc_e2.priority == 99

      processes = [proc_e2, proc_e1_1, proc_e1_2, proc_e1_3]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_e1_1 = Enum.find(result, &(&1.id == proc_e1_1.id))
      proc_e1_2 = Enum.find(result, &(&1.id == proc_e1_2.id))
      proc_e1_3 = Enum.find(result, &(&1.id == proc_e1_3.id))
      proc_e2 = Enum.find(result, &(&1.id == proc_e2.id))

      # There are 10 + 5 + 1 = 16 shares for `entity_1`, with 500 available CPU. This means that
      # each share accounts for 31.25MHz. Multiply that by the priority and you've got the total
      assert_decimal_eq(proc_e1_1.next_allocation.cpu, 31.25 * 10)
      assert_decimal_eq(proc_e1_2.next_allocation.cpu, 31.25 * 5)
      assert_decimal_eq(proc_e1_3.next_allocation.cpu, 31.25 * 1)

      # `entity_2` has 99 shares, but that is limited to 500MHz (its fair share)
      assert_decimal_eq(proc_e2.next_allocation.cpu, 500)
    end

    test "takes `limit` into consideration" do
      %{server: server, meta: %{resources: server_resources}} =
        Setup.server(resources: %{cpu: 1500})

      # `proc_1` has a limit of 100MHz, whereas `proc_2` has a limit on DLK/ULK
      proc_1 = Setup.process!(server.id, limit: %{cpu: 100})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 999_999})
      proc_3 = Setup.process!(server.id, limit: %{dlk: 1, ulk: 1, ram: 1})

      assert {:ok, result} = Allocator.allocate(server_resources, [proc_1, proc_2, proc_3])

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))

      # `proc_1`'s CPU allocation was limitted to 100, even though it could get up to 500MHz
      assert_decimal_eq(proc_1.next_allocation.cpu, 100)

      # `proc_2`'s CPU got all the 500MHz it had access to, because its limit was higher than that
      # PS: Read note at the end of the test
      assert_decimal_eq(proc_2.next_allocation.cpu, 500)

      # So did `proc_3`, which had no CPU limitations set
      # PS: Read note at the end of the test
      assert_decimal_eq(proc_3.next_allocation.cpu, 500)

      # Notice that even though `proc_3` had RAM limitation of 1MB, it did not apply because the
      # current allocation of 20MB comes from the static stage (minimum required allocation)
      assert_decimal_eq(proc_3.next_allocation.ram, 20)

      # NOTE: Server has 1500MHz of CPU, and yet a total of 500 + 500 + 100 = 1100MHz is being used.
      # There are 400MHz unallocated CPU, which could be spread across each process. In order to
      # support it, we need to do an extra pass on the processes after the dynamic allocation. TODO.
    end

    test "returns an error when server resources are insufficient" do
      # The server only has 200MB available
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{ram: 200})

      # Both servers need a minimum allocation of 250MB total
      proc_1 = Setup.process!(server.id, static: %{ram: 100})
      proc_2 = Setup.process!(server.id, static: %{ram: 150})

      assert {:error, {:overflow, [:ram]}} = Allocator.allocate(server_resources, [proc_1, proc_2])
    end
  end
end
