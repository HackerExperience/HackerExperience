defmodule Game.Process.TOP.Allocator do
  @moduledoc """
  Module responsible for allocating resources to the processes.
  """

  alias Game.Process.Resources

  def allocate(server_id, total_resources, processes) do
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

    # TODO: Add note about shares having to be per entity (not per server)
    {total_shares, proc_shares} =
      Enum.reduce(allocated_processes, {initial, []}, fn {process, proc_static_allocation},
                                                         {shares, acc} ->
        # Calculates number of shares the process should receive
        proc_shares = Resources.get_shares(process)

        # Accumulates total shares in use by the system
        shares = Resources.sum(shares, proc_shares)

        # This 3-tuple represents what is the process, how many static resources
        # are allocated to it, and how many (dynamic) shares it should receive
        # TODO: Reconsider this tuple approach for a more "normalized" data. Maybe a struct?
        proc_share_info = [{process, proc_static_allocation, proc_shares}]

        {shares, acc ++ proc_share_info}
      end)

    # Based on the total shares selected, figure out how many resources each
    # share shall receive
    resource_per_share =
      Resources.resource_per_share(available_resources, total_shares)

    # Dynamically allocate each process based on their shares * resource_per_share
    Enum.reduce(proc_shares, {initial, []}, fn {process, proc_static_allocation, proc_shares},
                                               {total_alloc, acc} ->
      # Allocates dynamic resources. "Naive" because it has not taken into consideration the process
      # limitations yet
      naive_dynamic_alloc = Resources.allocate_dynamic(proc_shares, resource_per_share, process)

      # Limit is TODO
      limit = %{}

      # Now we take the naive allocated amount and apply the process limitations
      proc_dynamic_alloc = Resources.min(naive_dynamic_alloc, limit)

      # Sums static and dynamic allocation, resulting on the final allocation
      proc_allocation = Resources.sum(proc_dynamic_alloc, proc_static_allocation)

      # Accumulate total alloc, in order to know how many resources were used
      total_alloc = Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, acc ++ [{process, proc_allocation}]}
    end)
  end
end
