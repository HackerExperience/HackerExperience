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

      # `proc_1`'s CPU allocation was limited to 100, even though it could get up to 500MHz
      assert_decimal_eq(proc_1.next_allocation.cpu, 100)

      # `proc_2`'s CPU got all the 500MHz it had access to, because its limit was higher than that
      assert_decimal_eq(proc_2.next_allocation.cpu, 700)

      # So did `proc_3`, which had no CPU limitations set
      assert_decimal_eq(proc_3.next_allocation.cpu, 700)

      # Notice that even though `proc_3` had RAM limitation of 1MB, it did not apply because the
      # current allocation of 20MB comes from the static stage (minimum required allocation)
      assert_decimal_eq(proc_3.next_allocation.ram, 20)
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

  # During the dynamic allocation stage, we need to make sure each entity receives their fair share
  # of resources. Let's imagine there are 2 entities making downloads in a single server, with 1
  # entity making 10 downloads and another entity making a single download. Both entities will get
  # 50% of the server's available bandwidth, with this being split evenly among each entity's
  # processes
  describe "allocate/2 - dynamic allocation with multiple entities" do
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

    test "takes into consideration resource type being used by each entity" do
      # Scenario: We have 4 entities with processes in the server. 3 of them are using the DLK
      # resource and 2 of them are using the CPU.
      %{server: server, entity: entity_1, meta: %{resources: server_resources}} =
        Setup.server(resources: %{cpu: 1000, dlk: 600})

      entity_2 = Setup.entity!()
      entity_3 = Setup.entity!()
      entity_4 = Setup.entity!()

      # Both entiteis will receive 500MHz each, with this total being shared evenly across the procs
      proc_cpu_1 = Setup.process!(server.id, entity_id: entity_1.id)
      proc_cpu_2 = Setup.process!(server.id, entity_id: entity_2.id)

      # Each entity will receive 200Mbps, with `proc_dlk_1` and `proc_dlk_2` sharing that evenly
      # since they belong to the same entity
      proc_dlk_1 = Setup.process!(server.id, entity_id: entity_2.id, type: :noop_dlk)
      proc_dlk_2 = Setup.process!(server.id, entity_id: entity_2.id, type: :noop_dlk)
      proc_dlk_3 = Setup.process!(server.id, entity_id: entity_3.id, type: :noop_dlk)
      proc_dlk_4 = Setup.process!(server.id, entity_id: entity_4.id, type: :noop_dlk)

      processes = [proc_cpu_1, proc_cpu_2, proc_dlk_1, proc_dlk_2, proc_dlk_3, proc_dlk_4]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_cpu_1 = Enum.find(result, &(&1.id == proc_cpu_1.id))
      proc_cpu_2 = Enum.find(result, &(&1.id == proc_cpu_2.id))
      proc_dlk_1 = Enum.find(result, &(&1.id == proc_dlk_1.id))
      proc_dlk_2 = Enum.find(result, &(&1.id == proc_dlk_2.id))
      proc_dlk_3 = Enum.find(result, &(&1.id == proc_dlk_3.id))
      proc_dlk_4 = Enum.find(result, &(&1.id == proc_dlk_4.id))

      assert_decimal_eq(proc_cpu_1.next_allocation.cpu, 500)
      assert_decimal_eq(proc_cpu_2.next_allocation.cpu, 500)
      assert_decimal_eq(proc_dlk_1.next_allocation.dlk, 100)
      assert_decimal_eq(proc_dlk_2.next_allocation.dlk, 100)
      assert_decimal_eq(proc_dlk_3.next_allocation.dlk, 200)
      assert_decimal_eq(proc_dlk_4.next_allocation.dlk, 200)
    end
  end

  # After the static and dynamic allocation, it's possible there are remaining resources. This could
  # happen when one of the processes have upper limits. In this case, we want to do another pass and
  # make sure the remaining resources are allocated. This can get particularly complex when multiple
  # processes with different limits are at play. This group of tests ensure the feature is working
  describe "allocate/2 - excess resources after dynamic allocation" do
    test "multiple processes with different resources being limited" do
      %{server: server, meta: %{resources: server_resources}} =
        Setup.server(resources: %{cpu: 1000, dlk: 600})

      # `proc_1` has a limit of 100MHz whereas `proc_2` has no limits. Server has 1000MHz. We
      # expect `proc_1` to use 100MHz and `proc_2` to use 900MHz.
      proc_1 = Setup.process!(server.id, limit: %{cpu: 100})
      proc_2 = Setup.process!(server.id)

      # `proc_3` has a DLK limit of 50Mbit, with `proc_4` and `proc_5` having no limits. With a
      # total server bandwidth of 600Mbit, we get 50 + 275 + 275 respectively
      proc_3 = Setup.process!(server.id, type: :noop_dlk, limit: %{dlk: 50})
      proc_4 = Setup.process!(server.id, type: :noop_dlk, limit: %{})
      proc_5 = Setup.process!(server.id, type: :noop_dlk, limit: %{})

      processes = [proc_1, proc_2, proc_3, proc_4, proc_5]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))
      proc_4 = Enum.find(result, &(&1.id == proc_4.id))
      proc_5 = Enum.find(result, &(&1.id == proc_5.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 100)
      assert_decimal_eq(proc_2.next_allocation.cpu, 900)
      assert_decimal_eq(proc_3.next_allocation.dlk, 50)
      assert_decimal_eq(proc_4.next_allocation.dlk, 275)
      assert_decimal_eq(proc_5.next_allocation.dlk, 275)
    end

    test "multiple processes with different limits (smaller than dynamic share)" do
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{cpu: 900})

      proc_1 = Setup.process!(server.id, limit: %{cpu: 100})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 150})
      proc_3 = Setup.process!(server.id)

      processes = [proc_1, proc_2, proc_3]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 100)
      assert_decimal_eq(proc_2.next_allocation.cpu, 150)
      assert_decimal_eq(proc_3.next_allocation.cpu, 650)
    end

    test "no (dynamic) resources left for excess allocation, despite processes having limits" do
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{cpu: 900})

      # Each process has a limit of 500MHz, but with a server total of 900MHz, each one will get
      # 450MHz from the dynamic stage. As such, the excess allocation should not be triggered
      proc_1 = Setup.process!(server.id, limit: %{cpu: 500})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 500})

      processes = [proc_1, proc_2]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 450)
      assert_decimal_eq(proc_2.next_allocation.cpu, 450)

      # TODO: Add some internal flag to make sure `iterate_excess_allocation` was never triggered
    end

    test "multiple processes with higher limits (post dynamic allocation)" do
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{cpu: 900})

      # Once `proc_1` hit its limit, there will be 900 - (200 + 300 + 300) = 100MHz left. These
      # 100MHz will be split evenly at 50MHz/remaining proc, which will not exceed the 500MHz limit
      proc_1 = Setup.process!(server.id, limit: %{cpu: 200})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 500})
      proc_3 = Setup.process!(server.id)

      processes = [proc_1, proc_2, proc_3]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 200)
      assert_decimal_eq(proc_2.next_allocation.cpu, 350)
      assert_decimal_eq(proc_3.next_allocation.cpu, 350)
    end

    test "multiple processes with smaller limits (post dynamic allocation)" do
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{cpu: 900})

      # Once `proc_1` hit its limit, there will be 900 - (200 + 300 + 300) = 100MHz left. These
      # 100MHz will be split evenly at 50MHz/remaining proc, but it can't be allocated evenly
      # because `proc_2` has a limit of 310MHz
      proc_1 = Setup.process!(server.id, limit: %{cpu: 200})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 310})
      proc_3 = Setup.process!(server.id)

      processes = [proc_1, proc_2, proc_3]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 200)
      assert_decimal_eq(proc_2.next_allocation.cpu, 310)
      assert_decimal_eq(proc_3.next_allocation.cpu, 350)

      # Note that, in this scenario, `proc_3` should actually get 390. This can be achieved by
      # performing the excess allocation recursively, until all processes are fully allocated or
      # all server resources are fully utilised. I'll leave this as a TODO, since we are getting
      # to the point of diminishing returns for an overly complex implementation.
    end

    test "all processes limited (post dynamic allocation)" do
      %{server: server, meta: %{resources: server_resources}} = Setup.server(resources: %{cpu: 900})

      proc_1 = Setup.process!(server.id, limit: %{cpu: 100})
      proc_2 = Setup.process!(server.id, limit: %{cpu: 350})
      proc_3 = Setup.process!(server.id, limit: %{cpu: 350})

      processes = [proc_1, proc_2, proc_3]
      assert {:ok, result} = Allocator.allocate(server_resources, processes)

      proc_1 = Enum.find(result, &(&1.id == proc_1.id))
      proc_2 = Enum.find(result, &(&1.id == proc_2.id))
      proc_3 = Enum.find(result, &(&1.id == proc_3.id))

      assert_decimal_eq(proc_1.next_allocation.cpu, 100)
      assert_decimal_eq(proc_2.next_allocation.cpu, 350)
      assert_decimal_eq(proc_3.next_allocation.cpu, 350)
    end
  end
end
