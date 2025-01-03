defmodule Game.Process.TOP.Allocator do
  @moduledoc """
  Module responsible for allocating resources to the processes.
  """

  require Logger
  alias Game.Process.Resources

  def allocate(_, []), do: {:ok, []}

  def allocate(%Resources{} = total_resources, processes) do
    # Static allocation
    {static_resources_usage, statically_allocated_processes} = static_allocation(processes)

    remaining_resources =
      Resources.sub(total_resources, static_resources_usage)

    # Dynamic allocation
    {dynamic_resources_usage, dynamically_allocated_processes} =
      dynamic_allocation(remaining_resources, statically_allocated_processes)

    # TODO: Implement this once we add process limitations
    # # Now we'll take another pass, in order to give a change for processes to
    # # claim unused resources. This may happen when a resource is reserved to a
    # # process, but the process does not allocate it due to upper limitations
    # {remaining_resources_usage, allocated_processes} =
    #   remaining_allocation(remaining_resources, allocated_processes)

    remaining_resources =
      Resources.sub(remaining_resources, dynamic_resources_usage)

    case Resources.overflow?(remaining_resources) do
      # No overflow, we did it!
      false ->
        {:ok, dynamically_allocated_processes}

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

      # Limit is TODO
      limit = Resources.initial()

      # Now we take the naive allocated amount and apply the process limitations
      proc_dynamic_alloc = Resources.max(naive_dynamic_alloc, limit)

      # Sums static and dynamic allocation, resulting on the final allocation
      proc_allocation = Resources.sum(proc_dynamic_alloc, proc_static_allocation)

      # Accumulate total alloc, in order to know how many resources were used
      total_alloc = Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, [%{process | next_allocation: proc_allocation} | acc]}
    end)
  end
end
