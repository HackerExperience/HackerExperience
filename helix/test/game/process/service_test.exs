defmodule Game.Services.ProcessTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc
  alias Game.Process.Log.Edit, as: LogEditProcess
  alias Game.Events.Process.Created, as: ProcessCreatedEvent

  setup [:with_game_db]

  describe "create/4" do
    test "creates a new process" do
      %{server: server, entity: entity} = Setup.server()
      log = Setup.log!(server.id)

      # TODO: This test is wrong, overall. I should generate the params the same way Executable does
      registry_data =
        %{
          l_dynamic: [:cpu],
          static: %{ram: 10},
          objective: %{cpu: 1000},
          tgt_log_id: log.id,
          limit: %{}
        }

      # Using `LogEditProcess` as a sample process
      process_data = LogEditProcess.new(%{type: :local_login, data: %{}}, %{})
      process_type = LogEditProcess.get_process_type(%{}, %{})
      process_info = {process_type, process_data}

      assert {:ok, process, [event]} =
               Svc.Process.create(server.id, entity.id, registry_data, process_info)

      assert process.server_id == server.id
      assert process.entity_id == entity.id
      assert process.data == process_data
      assert process.type == process_type
      assert process.registry == get_registry_params(registry_data)

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
