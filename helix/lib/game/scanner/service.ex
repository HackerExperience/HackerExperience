defmodule Game.Services.Scanner do
  require Logger
  alias Feeb.DB
  alias Renatils.Random
  alias Game.{Entity, ScannerInstance, ScannerTask, Server}

  @doc """
  Returns a ScannerInstance that matches the given filter.
  """
  @spec fetch_instance(list, list) ::
          ScannerInstance.t() | nil
  def fetch_instance(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:instances, :by_id}},
      by_entity_server_type: {:one, {:instances, :by_entity_server_type}}
    ]

    Core.with_context(:scanner, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @spec fetch_instance!(list, list) ::
          ScannerInstance.t() | no_return
  def fetch_instance!(filter_params, opts \\ []) do
    filter_params
    |> fetch_instance(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  @doc """
  Returns all ScannerInstances that match the given filter.
  """
  def list_instances(filter_params, opts \\ []) do
    filters = [
      by_entity_server: {:all, {:instances, :by_entity_server}}
    ]

    Core.with_context(:scanner, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns all ScannerTasks that match the given filter.
  """
  def list_tasks(filter_params, opts \\ []) do
    filters = [
      by_completed: {:all, {:tasks, :by_completion_date_lte}}
    ]

    Core.with_context(:scanner, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Sets up instances for all types. If one is found to already exist in the target server, a conflict
  resolution logic takes place.

  Setup is triggered on:
  - Gateway: Server creation
  - Gateway: Sync request
  - Endpoint: Tunnel creation

  # Conflict resolution

  If a Gateway instance is found to already exist, nothing needs to be done. If an Endpoint instance
  is found to already exist, we make sure that the `tunnel_id` is updated -- by recreating it.

  # Companion tasks

  For each newly created Instance, a Task is also created. At first, this task has no target -- it
  will eventually be retargeted by the corresponding worker.
  """
  def setup_instances(%Entity.ID{} = entity_id, %Server.ID{} = server_id, maybe_tunnel_id) do
    case list_instances(by_entity_server: [entity_id, server_id]) do
      # There are no instances, regular set up
      [] ->
        with {:ok, instances} <- do_setup_instances(entity_id, server_id, maybe_tunnel_id) do
          {:ok, instances, :setup}
        end

      # All 3 instances already exist. We'll verify their `tunnel_id` and update if necessary
      [_, _, _] = instances ->
        if Enum.any?(instances, &(&1.tunnel_id != maybe_tunnel_id)) do
          # If there is even one instance that doesn't match the tunnel ID, recreate all of them
          recreate_setup_instances(entity_id, server_id, maybe_tunnel_id)
        else
          {:ok, instances, :noop}
        end

      # Unexpected number of instances -- should never happen (ACID violation)
      instances ->
        Logger.warning("Expected 0 or 3 instances, got: #{inspect(instances)}")
        recreate_setup_instances(entity_id, server_id, maybe_tunnel_id)
    end
  end

  @doc """
  Destroys all Scanner instances for the given (entity_id, server_id) target.
  """
  def destroy_instances(%Entity.ID{} = e_id, %Server.ID{} = s_id) do
    Core.with_context(:scanner, :write, fn ->
      with {:ok, _} <- DB.delete_all({:tasks, :delete_by_entity_server}, [e_id, s_id]),
           {:ok, _} <- DB.delete_all({:instances, :delete_by_entity_server}, [e_id, s_id]) do
        Logger.info("Deleted scanner instances for (e=#{e_id}, s=#{s_id})")
        :ok
      end
    end)
  end

  @doc """
  Archives the old task and creates a new one with the given target.
  """
  def retarget_task(%ScannerTask{} = task, next_target_id, duration) do
    now = DateTime.utc_now()

    {target_id, target_sub_id} =
      case next_target_id do
        nil ->
          {nil, nil}

        {_target_id, _target_sub_id} ->
          next_target_id

        target_id when is_integer(target_id) ->
          {target_id, nil}
      end

    completion_date =
      now
      |> DateTime.add(duration, :second)
      |> DateTime.to_unix()

    changes = %{
      run_id: Random.uuid(),
      target_id: target_id,
      target_sub_id: target_sub_id,
      scheduled_at: now,
      completion_date: completion_date
    }

    Core.with_context(:scanner, :write, fn ->
      with {:ok, updated_task} <- do_update_task(task, changes) do
        # TODO: Archive the previous run
        {:ok, updated_task}
      end
    end)
  end

  defp do_update_task(task, changes) do
    task
    |> ScannerTask.update(changes)
    |> DB.update()
  end

  defp do_setup_instances(entity_id, server_id, tunnel_id) do
    create_instance_fn = fn type ->
      create_instance(entity_id, server_id, type, tunnel_id, %{})
    end

    create_task_fn = fn instance ->
      # TODO: Jitter
      create_task(instance, duration: 60)
    end

    Core.with_context(:scanner, :write, fn ->
      with {:i_conn, {:ok, conn_instance}} <- {:i_conn, create_instance_fn.(:connection)},
           {:i_file, {:ok, file_instance}} <- {:i_file, create_instance_fn.(:file)},
           {:i_log, {:ok, log_instance}} <- {:i_log, create_instance_fn.(:log)},
           {:t_conn, {:ok, _conn_task}} <- {:t_conn, create_task_fn.(conn_instance)},
           {:t_file, {:ok, _file_task}} <- {:t_file, create_task_fn.(file_instance)},
           {:t_log, {:ok, _log_task}} <- {:t_log, create_task_fn.(log_instance)} do
        {:ok, [conn_instance, file_instance, log_instance]}
      else
        {step, {:error, reason}} ->
          Logger.error("Unable to setup instance\n#{inspect(step)} - #{inspect(reason)}")
          {:error, reason}
      end
    end)
  end

  defp recreate_setup_instances(entity_id, server_id, tunnel_id) do
    Core.with_context(:scanner, :write, fn ->
      with :ok <- destroy_instances(entity_id, server_id),
           {:ok, instances} <- do_setup_instances(entity_id, server_id, tunnel_id) do
        {:ok, instances, :recreated}
      end
    end)
  end

  defp create_instance(entity_id, server_id, type, tunnel_id, target_params) do
    %{
      entity_id: entity_id,
      server_id: server_id,
      type: type,
      tunnel_id: tunnel_id,
      target_params: target_params
    }
    |> ScannerInstance.new()
    |> DB.insert()
  end

  defp create_task(%ScannerInstance{} = instance, opts) do
    duration = Keyword.fetch!(opts, :duration)
    now = DateTime.utc_now()

    completion_date =
      now
      |> DateTime.add(duration, :second)
      |> DateTime.to_unix()

    %{
      instance_id: instance.id,
      run_id: Random.uuid(),
      entity_id: instance.entity_id,
      server_id: instance.server_id,
      type: instance.type,
      target_id: nil,
      target_sub_id: nil,
      scheduled_at: now,
      completion_date: completion_date,
      next_backoff: opts[:next_backoff],
      failed_attempts: opts[:failed_attempts] || 0
    }
    |> ScannerTask.new()
    |> DB.insert()
  end
end
