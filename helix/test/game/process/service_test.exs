defmodule Game.Services.ProcessTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc
  alias Game.Events.Process.Created, as: ProcessCreatedEvent

  setup [:with_game_db]

  describe "create/4" do
    test "creates a new process" do
      %{server: server, entity: entity} = Setup.server()

      spec = Setup.process_spec(server.id, entity.id, type: :log_edit)

      assert {:ok, process, [event]} =
               Svc.Process.create(server.id, entity.id, spec.registry_data, spec.process_info)

      assert process.server_id == server.id
      assert process.entity_id == entity.id
      assert process.data == spec.data
      assert process.type == spec.type
      assert process.registry == get_registry_params(spec.registry_data)

      assert event.data.__struct__ == ProcessCreatedEvent
      assert event.data.process == process
      refute event.data.confirmed
    end
  end

  defp get_registry_params(registry_data) do
    registry_data
    |> Map.take(Game.ProcessRegistry.__cols__())
  end
end
