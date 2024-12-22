defmodule Game.Services.ProcessTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "create/4" do
    test "creates a new process" do
      %{server: server, entity: entity} = Setup.server()
      log = Setup.log!(server.id)

      registry_data =
        %{
          tgt_log_id: log.id
        }

      # TODO
      process_data = %{}
      process_type = :log_edit
      process_info = {process_type, process_data}

      Svc.Process.create(server.id, entity.id, registry_data, process_info)
      |> IO.inspect()
    end
  end
end
