defmodule Game.Process.TOP.Allocator do
  @moduledoc """
  Module responsible for allocating resources to the processes.

  # The allocation algorithm

  Allocation can be broken down in three major steps:

  1. Static allocation
  2. Dynamic allocation
  3. Excess allocation

  Once all processes have gone through the 3 steps, we make sure the allocated resources do not
  exceed the available resources in the server (overflow).

  By the end of the execution, in the success case, we'll return a list of process with the
  `next_allocation` field set to what should be considered the new allocation for the process. This
  module is pure: it makes no database operations. It's up to the consumer of this module (the TOP)
  to persist the allocation.

  ## Step 1 - Static allocation

  The first step allocates "static resources", that is, a mandatory, minimum set of resources that
  must be consumed by each process during its lifetime.

  It is static because it does not vary based on how many resources are available in the server. It
  is mandatory because, if the server does not have sufficient resources to fulfill the static
  allocation, then an overflow will happen.

  Each process can define the static resources, and they can be different based on whether the
  process is paused or running.

  Most commonly, you'll see RAM being used as static resource, as that is the main hardware resource
  used to limit the number of processes a server can hold at any given time.

  ## Step 2 - Dynamic allocation

  The dynamic allocation happens after the static allocation and will optimistically reserve all
  of the remaining server resources to the processes.

  Each process will want to allocate a specific set of "dynamic" resources (defined by the
  `dynamic/3` callback of the process Resourceable). For example, a process that is downloading a
  file will want to use the DLK resource dynamically. In this scenario, if this is the only process
  using DLK in the server, it should receive 100% of the available DLK in the server.

  The dynamic allocation step is meant to be fair: each unique *entity* with processes in the
  server will receive one share of the available resources.

  Example: 1 entity with any number of processes: this entity can dynamically allocate 100% of the
  remaining server resources. If a second entity starts a process, then each entity is entitled to
  50% of the server resources. If a third entity joins the party, each will now get 33% and so on.

  From the resources reserved to the entity, one process may be given higher priority than another.
  That's where `priority` (sometimes referred to as "nice") comes in: an entity can "redirect" the
  dynamically allocated resources to a particular process by assigning a high priority to it.

  Notice that the priority only affects the allocation of resources within the *entity's* available
  pool of resources. Increasing priority of a process should never "steal" resources that are
  reserved to another entity.

  Remember when I said that the dynamic allocation is "optimistic"? Well, that's what I meant by it:
  each entity is *reserved* a share of the remaining resources, but it may not use them fully.

  Examples of partial utilization include:

  1. All processes from Entity E1 use only resource R1. The resources R2..Rn that were reserved to
     E1 are never allocated.
  2. Some processes from Entity E1 have an upper limit (defined by the `limit/3` callback of
     Resourceable) that is lower than the reserved amount of the corresponding resource.
  3. All processes from entity E1 are paused.

  The example 1 above is actually handled at the dynamic step: the total server resources are shared
  evenly based on the number of dynamically allocated resources per unique entity. The remaining
  examples, however, could lead to the scenario where not all of the reserved resources are
  allocated, which leads us to the next step.

  ## Step 3 - Excess allocation

  The excess allocation happens after the dynamic allocation, and will optimistically allocate the
  remaining reserved-but-not-allocated resources from the dynamic step. Refer to the documentation
  of the Dynamic Allocation step for some example scenarios where this could happen.

  Excess allocation is essentially a no-op if the dynamic allocation successfully allocated all of
  the server resources (which is obvious -- there was no excess, so there is no excess allocation).

  Similar to the dynamic allocation, the excess allocation step also tries to be fair: it looks at
  how many processes, from all entities, would benefit from the excess allocation and tries to
  allocate the remaining resources evenly (regardless of priority).

  Note that the process priority does not influence excess allocation. Priority is only taken into
  consideration during the dynamic allocation step.

  The processes that could benefit from excess allocation are:

  - Unlimited processes (i.e. processes that have no upper limit).
  - Limited processes that have not reached the upper limit.

  Processes that do not receive excess allocation are:

  - Limited processes who already hit the upper limit of their allocation.
  - Processes that use dynamic resources for which there was no excess[0].

  [0] - It's entirely possible that some resources were fully allocated in the dynamic allocation
  step, whereas some resources were only partially allocated and are in excess.

  You may have noticed I said that the excess allocation is also optimistic. Maybe a more accurate
  description is that the excess allocation step does not try to be perfect. It could be improved,
  but at least for the time being I'm explicitly *not* making it perfect for simplicity sake.

  There are scenarios in which the excess allocation is not fully utilized by one process, but could
  benefit another process. At the moment, when this happen, the resource is left unallocated.

  A solution to this would be to recursively perform the excess allocation step until either all
  server resources are fully allocated or all processes have hit their respective upper limit. This
  is a non-goal for now.
  """

  use Docp
  require Logger
  alias Game.Process.Resources
  alias Game.Process

  @initial Resources.initial()
  @zero Decimal.new(0)

  @spec allocate(total_server_resources :: Resources.t(), [Process.t()]) ::
          {:ok, [Process.t()]}
          | {:error, {:overflow, [Resources.name()]}}
  def allocate(%Resources{} = total_resources, [_ | _] = processes) do
    # Static allocation
    {static_resources_usage, statically_allocated_processes} = static_allocation(processes)

    remaining_resources =
      Resources.sub(total_resources, static_resources_usage)

    # Dynamic allocation
    {dynamic_resources_usage, dynamically_allocated_processes} =
      dynamic_allocation(remaining_resources, statically_allocated_processes)

    remaining_resources =
      Resources.sub(remaining_resources, dynamic_resources_usage)

    # Excess allocation
    {excess_resources_usage, fully_allocated_processes} =
      excess_allocation(remaining_resources, dynamically_allocated_processes)

    remaining_resources =
      Resources.sub(remaining_resources, excess_resources_usage)

    case Resources.overflow?(remaining_resources) do
      # No overflow, we did it!
      false ->
        {:ok, fully_allocated_processes}

      # We were unable to allocate these processes because the following resources overflowed
      {true, overflowed_resources} ->
        {:error, {:overflow, overflowed_resources}}
    end
  end

  def allocate(_, []), do: {:ok, []}

  defp static_allocation(processes) do
    Enum.reduce(processes, {@initial, []}, fn process, {allocated, acc} ->
      proc_static_allocation = Resources.allocate_static(process)

      allocated = Resources.sum(allocated, proc_static_allocation)

      {allocated, [{process, proc_static_allocation} | acc]}
    end)
  end

  defp dynamic_allocation(available_resources, allocated_processes) do
    # How many different entities have active processes in this server. This will be used to
    # calculate how many server resources should be reserved for each entity.
    unique_entities_per_resource =
      allocated_processes
      |> Enum.group_by(fn {%{entity_id: entity_id}, _} -> entity_id end)
      |> Enum.reduce(Map.from_struct(@initial), fn {_, entity_allocated_processes}, acc ->
        uniq_resources_in_use =
          Enum.reduce(entity_allocated_processes, [], fn {process, _}, iacc ->
            # TODO: This will break in the event of multiple resources
            [res] = process.resources.dynamic
            if res not in iacc, do: [res | iacc], else: iacc
          end)

        Enum.map(acc, fn {res, v} ->
          if res in uniq_resources_in_use, do: {res, Decimal.add(v, 1)}, else: {res, v}
        end)
      end)
      |> Resources.from_map()

    {total_entity_shares, proc_shares} =
      Enum.reduce(allocated_processes, {%{}, []}, fn {process, proc_static_allocation},
                                                     {acc_entity_shares, acc} ->
        entity_shares = acc_entity_shares[process.entity_id] || @initial

        # Calculates number of shares the process should receive
        proc_shares =
          if process.status != :paused do
            Resources.get_shares(process)
          else
            # Paused processes receive no dynamic allocation (but they receive static allocation)
            @initial
          end

        # Accumulates total shares in use by this entity
        new_entity_shares = Resources.sum(entity_shares, proc_shares)

        # This 3-tuple represents what is the process, how many static resources
        # are allocated to it, and how many (dynamic) shares it should receive
        # TODO: Reconsider this tuple approach for a more "normalized" data. Maybe a struct?
        proc_share_info = [{process, proc_static_allocation, proc_shares}]

        {Map.put(acc_entity_shares, process.entity_id, new_entity_shares), acc ++ proc_share_info}
      end)

    # Each entity will be reserved its fair fraction of the total server resources
    available_resources_per_entity =
      Resources.div(available_resources, unique_entities_per_resource)

    # Based on the total shares selected, figure out how many resources each share shall receive.
    # Different entities may have different number of shares (due to different number of processes
    # and/or processes with different priorities). However, the total resources each entity can use
    # in the server is always the same. If we were to multiply resources_per_entity_share with
    # entity_shares, we'd get the same value for every entity (available_resources_per_entity).
    resource_per_entity_share =
      Enum.map(total_entity_shares, fn {entity_id, entity_shares} ->
        {entity_id, Resources.resource_per_share(available_resources_per_entity, entity_shares)}
      end)
      |> Map.new()

    # Dynamically allocate each process based on their shares * resource_per_share
    Enum.reduce(proc_shares, {@initial, []}, fn {process, proc_static_allocation, proc_shares},
                                                {total_alloc, acc} ->
      resource_per_share = Map.fetch!(resource_per_entity_share, process.entity_id)

      # Allocates dynamic resources. "Naive" because it has not taken into consideration the process
      # limitations yet
      naive_dynamic_alloc = Resources.allocate_dynamic(proc_shares, resource_per_share, process)

      limit = process.resources.limit

      # Now we take the naive allocated amount and apply the process limitations
      proc_dynamic_alloc = Resources.apply_limits(naive_dynamic_alloc, limit)

      # Sums static and dynamic allocation, resulting on the final allocation
      proc_allocation = Resources.sum(proc_dynamic_alloc, proc_static_allocation)

      # Accumulate total alloc, in order to know how many resources were used
      total_alloc = Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, [%{process | next_allocation: proc_allocation} | acc]}
    end)
  end

  defp excess_allocation(remaining_resources, allocated_processes) do
    # Grab information about processes that have room for more resources
    {total_dynamic_shares, limited_processes, unlimited_processes} =
      Enum.reduce(allocated_processes, {@initial, %{}, %{}}, fn
        process, {acc_total_dynamic_shares, acc_limited, acc_unlimited} = acc ->
          case excess_lookup(process, acc_total_dynamic_shares) do
            {:limited_unavailable, _, _, _} ->
              acc

            {:limited_available, allocation_available, shares, new_total_dynamic_shares} ->
              new_acc_limited = Map.put(acc_limited, process.id, {shares, allocation_available})
              {new_total_dynamic_shares, new_acc_limited, acc_unlimited}

            {:unlimited, allocation_available, shares, new_total_dynamic_shares} ->
              new_acc_unlimited = Map.put(acc_unlimited, process.id, {shares, allocation_available})
              {new_total_dynamic_shares, acc_limited, new_acc_unlimited}
          end
      end)

    # "Naive" amount that can be shared across every remaining process, based on how many processes
    # using dynamic allocation of each resource are left. It's naive because the process may have a
    # limit of its own, which would not allow the resources to be used in full
    resource_per_process =
      Resources.resource_per_share(remaining_resources, total_dynamic_shares)

    # If the processes left to receive more allocation would receive zero additional allocation,
    # we can skip the excess allocation entirely. This may happen when, for instance, we have
    # available RAM in the server, but no processes are allocating RAM dynamically
    perform_excess_allocation? =
      not Resources.equal?(resource_per_process, @initial)

    if perform_excess_allocation? do
      Enum.reduce(allocated_processes, {@initial, []}, fn process, {total_alloc, acc} ->
        case {unlimited_processes[process.id], limited_processes[process.id]} do
          # The process is unlimited and will benefit from excess allocation
          {{shares, available}, nil} ->
            {new_total_alloc, process} =
              do_excess_alloc(process, total_alloc, resource_per_process, shares, available)

            {new_total_alloc, [process | acc]}

          # The process is limited but has room for (some) excess allocation
          {nil, {shares, available}} ->
            {new_total_alloc, process} =
              do_excess_alloc(process, total_alloc, resource_per_process, shares, available)

            {new_total_alloc, [process | acc]}

          # The process is limited has already been allocated in full; nothing to change
          {nil, nil} ->
            {total_alloc, [process | acc]}
        end
      end)
    else
      {@initial, allocated_processes}
    end
  end

  defp do_excess_alloc(process, total_alloc, resource_per_process, shares, available_alloc) do
    # Maximum amount of excess allocation we can provide to this process
    naive_excess_allocation = Resources.mul(resource_per_process, shares)

    # If the process is "unlimited", then we can apply as many resources as we have available
    excess_allocation =
      if available_alloc == :infinity do
        naive_excess_allocation

        # Process is limited, we can apply resources up to its own limit
      else
        Resources.min(naive_excess_allocation, available_alloc)
      end

    # New total allocation for the process, which takes into consideration the excess allocation
    new_next_allocation = Resources.sum(process.next_allocation, excess_allocation)

    # Accumulate total alloc, in order to know how many excess resources were used
    total_alloc = Resources.sum(total_alloc, excess_allocation)

    {total_alloc, %{process | next_allocation: new_next_allocation}}
  end

  @docp """
  Grabs information about the process regarding its allocation status and how many resources can
  still be allocated to it, if any.
  """
  defp excess_lookup(process, total_dynamic_shares) do
    has_limit? = not Resources.equal?(process.resources.limit, @initial)
    dynamic_resources = process.resources.dynamic

    # Resources with a 1/0 value for each resource the process allocates dynamically
    dynamic_shares =
      @initial
      |> Map.from_struct()
      |> Enum.map(fn {res, _} ->
        if res in dynamic_resources, do: {res, Decimal.new(1)}, else: {res, @zero}
      end)
      |> Resources.from_map()

    new_total_dynamic_shares = Resources.sum(total_dynamic_shares, dynamic_shares)

    if has_limit? do
      allocation_available =
        Resources.sub(process.resources.limit, process.next_allocation)
        |> Map.from_struct()
        |> Enum.map(fn {res, v} ->
          if res not in dynamic_resources, do: {res, @zero}, else: {res, v}
        end)
        |> Resources.from_map()

      if Resources.equal?(allocation_available, @initial) do
        {:limited_unavailable, @initial, @initial, total_dynamic_shares}
      else
        {:limited_available, allocation_available, dynamic_shares, new_total_dynamic_shares}
      end
    else
      {:unlimited, :infinity, dynamic_shares, new_total_dynamic_shares}
    end
  end
end
