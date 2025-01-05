defmodule Game.Process.TOP.Allocator do
  @moduledoc """
  Module responsible for allocating resources to the processes.
  """

  use Docp
  require Logger
  alias Game.Process.Resources

  @initial Resources.initial()
  @zero Decimal.new(0)

  def allocate(_, []), do: {:ok, []}

  def allocate(%Resources{} = total_resources, processes) do
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

  defp static_allocation(processes) do
    initial = Resources.initial()

    Enum.reduce(processes, {initial, []}, fn process, {allocated, acc} ->
      proc_static_allocation = Resources.allocate_static(process)

      allocated = Resources.sum(allocated, proc_static_allocation)

      {allocated, [{process, proc_static_allocation} | acc]}
    end)
  end

  defp dynamic_allocation(available_resources, allocated_processes) do
    initial = Resources.initial()

    # How many different entities have active processes in this server. This will be used to
    # calculate how many server resources should be reserved for each entity.
    total_unique_entities =
      Enum.reduce(allocated_processes, {0, %{}}, fn {process, _}, {acc_count, acc_entities} ->
        if Map.has_key?(acc_entities, process.entity_id) do
          {acc_count, acc_entities}
        else
          {acc_count + 1, Map.put(acc_entities, process.entity_id, true)}
        end
      end)
      |> elem(0)

    {total_entity_shares, proc_shares} =
      Enum.reduce(allocated_processes, {%{}, []}, fn {process, proc_static_allocation},
                                                     {acc_entity_shares, acc} ->
        entity_shares = acc_entity_shares[process.entity_id] || initial

        # Calculates number of shares the process should receive
        proc_shares =
          if process.status != :paused do
            Resources.get_shares(process)
          else
            # Paused processes receive no dynamic allocation (but they receive static allocation)
            initial
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
      Resources.map(available_resources, &Decimal.div(&1, total_unique_entities))

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
    Enum.reduce(proc_shares, {initial, []}, fn {process, proc_static_allocation, proc_shares},
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
    dynamic_resources = process.resources.l_dynamic

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
