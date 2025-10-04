defmodule Game.Services.Scanner do
  require Logger
  alias Feeb.DB
  alias Game.{Entity, ScannerInstance, Server}

  @doc """
  Returns a ScannerInstance that matches the given filter.
  """
  @spec fetch(list, list) ::
          ScannerInstance.t() | nil
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_entity_server_type: {:one, {:instances, :by_entity_server_type}}
    ]

    Core.with_context(:scanner, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns all ScannerInstances that match the given filter.
  """
  def list(filter_params, opts \\ []) do
    filters = [
      by_entity_server: {:all, {:instances, :by_entity_server}}
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
  """
  def setup_instances(%Entity.ID{} = entity_id, %Server.ID{} = server_id, maybe_tunnel_id) do
    case list(by_entity_server: [entity_id, server_id]) do
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
  def destroy_instances(%Entity.ID{} = entity_id, %Server.ID{} = server_id) do
    Core.with_context(:scanner, :write, fn ->
      with {:ok, _} <-
             DB.delete_all({:instances, :delete_by_entity_server}, [entity_id, server_id]) do
        Logger.info("Deleted scanner instances for (e=#{entity_id}, s=#{server_id})")
        :ok
      end
    end)
  end

  defp do_setup_instances(entity_id, server_id, tunnel_id) do
    create_fn = fn type ->
      create_instance(entity_id, server_id, type, tunnel_id, %{})
    end

    Core.with_context(:scanner, :write, fn ->
      # This duplicate `list` call is here in the event of an (unlikely) race condition. Unique DB
      # constriant checks would apply at the DB layer, but better to handle it gracefully here
      with {:initial_state, []} <- {:initial_state, list(by_entity_server: [entity_id, server_id])},
           {:connection, {:ok, conn_instance}} <- {:connection, create_fn.(:connection)},
           {:file, {:ok, file_instance}} <- {:file, create_fn.(:file)},
           {:log, {:ok, log_instance}} <- {:log, create_fn.(:log)} do
        {:ok, [conn_instance, file_instance, log_instance]}
      else
        {:initial_state, instances} ->
          Logger.warning("Race condition detected -- returning recently created instances")
          {:ok, instances}

        {step, {:error, reason}} ->
          Logger.error(
            "Unable to setup instance\nStep: #{inspect(step)}\nReason: #{inspect(reason)}"
          )
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
end
