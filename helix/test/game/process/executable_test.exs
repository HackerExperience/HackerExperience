defmodule Game.Process.ExecutableTest do
  use Test.DBCase, async: true

  alias Game.Process.Executable
  alias Game.Process.Log.Edit, as: LogEditProcess
  alias Test.Process.NoopDLK, as: NoopDLKProcess

  setup [:with_game_db]

  describe "Execute/5" do
    test "creates the event with the expected data" do
      %{server: server, entity: entity} = Setup.server()
      log = Setup.log!(server.id)

      params = %{
        type: :local_login,
        data: %{}
      }

      meta = %{log: log}

      assert {:ok, process, [event]} =
               Executable.execute(LogEditProcess, server.id, entity.id, params, meta)

      assert process.type == :log_edit
      assert process.server_id == server.id
      assert process.entity_id == entity.id
      assert process.registry.tgt_log_id == log.id
      assert process.data.log_type == :local_login

      assert event.data.__struct__ == Game.Events.Process.Created
      assert event.data.process == process
      refute event.data.confirmed
    end

    test "stores the result of Resourceable's limit" do
      %{server: server, entity: entity} = Setup.server()

      meta = %{}
      params = %{ulk_limit: 1000}

      assert {:ok, process, _events} =
               Executable.execute(NoopDLKProcess, server.id, entity.id, params, meta)

      assert_decimal_eq(process.resources.limit.ulk, 1000)
      assert_decimal_eq(process.resources.limit.cpu, 0)
    end
  end
end
