defmodule Game.Services.Process do
  alias Feeb.DB
  alias Game.{Process, ProcessRegistry}
  alias Game.Events.Process.Created, as: ProcessCreatedEvent

  def create(server_id, entity_id, registry_data, process_info) do
    with {:ok, process} <- insert_process(server_id, entity_id, registry_data, process_info),
         {:ok, _registry} <- insert_registry(process, registry_data) do
      event = ProcessCreatedEvent.new(process, confirmed: false)
      {:ok, process, [event]}
    end
  end

  defp insert_process(server_id, entity_id, registry_data, {process_type, process_data}) do
    Core.with_context(:server, server_id, :write, fn ->
      %{
        entity_id: entity_id,
        type: process_type,
        data: process_data,
        registry: registry_data,
        resources: %{
          l_dynamic: registry_data.l_dynamic,
          objective: registry_data.objective,
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
      |> merge_registry_params(registry_data)
      |> ProcessRegistry.new()
      |> DB.insert()
    end)
  end

  defp merge_registry_params(params, registry_data) do
    registry_data
    |> Map.take(ProcessRegistry.__cols__())
    |> Map.merge(params)
  end
end
