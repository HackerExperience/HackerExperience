defmodule Game.Services.Process do
  alias Feeb.DB
  alias Game.{Process, ProcessRegistry}

  alias Game.Events.Process.Created, as: ProcessCreatedEvent
  alias Game.Events.Process.Completed, as: ProcessCompletedEvent

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:processes, :fetch}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  def create(server_id, entity_id, registry_data, process_info) do
    with {:ok, process} <- insert_process(server_id, entity_id, registry_data, process_info),
         {:ok, _registry} <- insert_registry(process, registry_data) do
      event = ProcessCreatedEvent.new(process, confirmed: false)
      {:ok, process, [event]}
    end
  end

  def delete(%Process{} = process, reason) when reason in [:completed, :killed] do
    Core.with_context(:server, process.server_id, :write, fn ->
      DB.delete!(process)
    end)

    Core.with_context(:universe, :write, fn ->
      # This is, of course, TODO. FeebDB needs to support delete based on query
      # (akin to Repo.delete_all)
      process_registry =
        DB.all(ProcessRegistry)
        |> Enum.find(&(&1.server_id == process.server_id && &1.process_id == process.id))

      DB.delete!({:processes_registry, :delete}, process_registry, [process.server_id, process.id])
    end)

    event =
      case reason do
        :completed ->
          ProcessCompletedEvent.new(process)

        :killed ->
          # TODO
          # ProcessKilledEvent.new(process)
          nil
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
        resources: %{
          l_dynamic: registry_data.l_dynamic,
          objective: registry_data.objective,
          static: registry_data.static,
          # When a process is created, it hasn't been allocated any resources yet
          allocated: nil,
          # Similarly, it hasn't processed anything yet
          processed: nil
        }
      }
      |> Process.new()
      |> DB.insert()
    end)
  end

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
