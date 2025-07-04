defmodule Game.Services.Process do
  alias Feeb.DB
  alias Game.{Entity, Process, ProcessRegistry, Server}

  alias Game.Events.Process.Created, as: ProcessCreatedEvent
  alias Game.Events.Process.Completed, as: ProcessCompletedEvent
  alias Game.Events.Process.Killed, as: ProcessKilledEvent
  alias Game.Events.Process.Paused, as: ProcessPausedEvent
  alias Game.Events.Process.Resumed, as: ProcessResumedEvent
  alias Game.Events.Process.Reniced, as: ProcessRenicedEvent

  @doc """
  Fetches a Process matching the given filters.
  """
  @spec fetch(Server.id(), list, list) ::
          Process.t() | nil
  def fetch(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:processes, :fetch}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Fetches a Process matching the given filters. The Process must exist or it will raise an error.
  """
  @spec fetch!(Server.id(), list, list) ::
          Process.t() | no_return
  def fetch!(%Server.ID{} = server_id, filter_params, opts \\ []) do
    server_id
    |> fetch(filter_params, opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  @doc """
  Returns a list of Process matching the given filters.
  """
  def list(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      query: &query/1,
      by_entity: {:all, {:processes, :by_entity}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Fetches a ProcessRegistry matching the given filters.
  """
  @spec fetch_registry(list, list) ::
          ProcessRegistry.t() | nil
  def fetch_registry(filter_params, opts \\ []) do
    filters = [
      by_process: &query_registry_by_process/1
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  @doc """
  Fetches a ProcessRegistry matching the given filters. The ProcessRegistry must exist or it will
  raise an error.
  """
  @spec fetch_registry!(list, list) ::
          ProcessRegistry.t() | no_return
  def fetch_registry!(filter_params, opts \\ []) do
    filter_params
    |> fetch_registry(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  @doc """
  Returns a list of ProcessRegistry matching the given filters.
  """
  @spec list_registry(list, list) ::
          [ProcessRegistry.t()]
  def list_registry(filter_params, opts \\ []) do
    filters = [
      query: &registry_query/1,
      by_src_file_id: {:all, {:processes_registry, :by_src_file_id}},
      by_tgt_file_id: {:all, {:processes_registry, :by_tgt_file_id}},
      by_tgt_log_id: {:all, {:processes_registry, :by_tgt_log_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  @spec create(Server.id(), Entity.id(), map, term) ::
          {:ok, Process.t(), [ProcessCreatedEvent.event()]}
          | {:error, term}
  def create(server_id, entity_id, registry_data, process_info) do
    with {:ok, process} <- insert_process(server_id, entity_id, registry_data, process_info),
         {:ok, _registry} <- insert_registry(process, registry_data) do
      event = ProcessCreatedEvent.new(process, confirmed: false)
      {:ok, process, [event]}
    end
  end

  @spec pause(Process.t()) ::
          {:ok, Process.t(), [ProcessPausedEvent.event()]}
          | {:error, term}
  def pause(%Process{status: :running} = process) do
    result =
      Core.with_context(:server, process.server_id, :write, fn ->
        process
        |> Process.update(%{status: :paused})
        |> DB.update()
      end)

    case result do
      {:ok, _} ->
        new_process = fetch!(process.server_id, by_id: process.id)
        event = ProcessPausedEvent.new(new_process)
        {:ok, new_process, [event]}

      {:error, _} = error ->
        error
    end
  end

  def pause(%Process{status: status}),
    do: {:error, {:cant_pause, status}}

  @spec resume(Process.t()) ::
          {:ok, Process.t(), [ProcessResumedEvent.event()]}
          | {:error, term}
  def resume(%Process{status: :paused} = process) do
    result =
      Core.with_context(:server, process.server_id, :write, fn ->
        # The resumed process will be allocated resources at the next TOP allocation
        process
        |> Process.update(%{status: :awaiting_allocation})
        |> DB.update()
      end)

    case result do
      {:ok, _} ->
        new_process = fetch!(process.server_id, by_id: process.id)
        event = ProcessResumedEvent.new(new_process)
        {:ok, new_process, [event]}

      {:error, _} = error ->
        error
    end
  end

  def resume(%Process{status: status}),
    do: {:error, {:cant_resume, status}}

  @spec renice(Process.t(), Process.priority()) ::
          {:ok, Process.t(), [ProcessRenicedEvent.event()]}
          | {:error, term}
  def renice(%Process{status: :running} = process, priority) do
    result =
      Core.with_context(:server, process.server_id, :write, fn ->
        process
        |> Process.update(%{priority: priority})
        |> DB.update()
      end)

    case result do
      {:ok, _} ->
        new_process = fetch!(process.server_id, by_id: process.id)
        event = ProcessRenicedEvent.new(new_process)
        {:ok, new_process, [event]}

      {:error, _} = error ->
        error
    end
  end

  def renice(%Process{status: status}),
    do: {:error, {:cant_renice, status}}

  @spec delete(Process.t(), atom) ::
          {:ok, ProcessCompletedEvent.event() | ProcessKilledEvent.event()}
  def delete(%Process{} = process, reason) when reason in [:completed, :killed] do
    Core.with_context(:server, process.server_id, :write, fn ->
      DB.delete!(process)
    end)

    Core.with_context(:universe, :write, fn ->
      DB.delete_all!({:processes_registry, :delete}, [process.server_id, process.id])
    end)

    event =
      case reason do
        :completed ->
          ProcessCompletedEvent.new(process)

        :killed ->
          ProcessKilledEvent.new(process, reason)
      end

    {:ok, event}
  end

  defp insert_process(server_id, entity_id, registry_data, {process_type, process_data}) do
    Core.with_context(:server, server_id, :write, fn ->
      %{
        entity_id: entity_id,
        type: process_type,
        data: process_data,
        registry: get_registry_params(registry_data),
        status: :awaiting_allocation,
        resources: %{
          dynamic: registry_data.dynamic,
          objective: registry_data.objective,
          static: registry_data.static,
          limit: registry_data.limit,
          # When a process is created, it hasn't been allocated any resources yet
          allocated: nil,
          # Similarly, it hasn't processed anything yet
          processed: nil
        },
        priority: 3
      }
      |> Process.new()
      |> DB.insert()
    end)
  end

  defp query(:all),
    do: DB.all(Process)

  defp registry_query(:servers_with_processes),
    do: DB.all({:processes_registry, :servers_with_processes}, [], format: :map)

  defp registry_query(:all),
    do: DB.all(ProcessRegistry, [])

  defp query_registry_by_process(%Process{id: process_id, server_id: server_id}),
    do: DB.one({:processes_registry, :fetch}, [server_id, process_id])

  defp insert_registry(%Process{} = process, registry_data) do
    Core.with_context(:universe, :write, fn ->
      %{
        server_id: process.server_id,
        process_id: process.id,
        entity_id: process.entity_id
      }
      |> Map.merge(get_registry_params(registry_data))
      |> ProcessRegistry.new()
      |> DB.insert()
    end)
  end

  defp get_registry_params(registry_data) do
    registry_data
    |> Map.take(ProcessRegistry.__cols__())
  end
end
