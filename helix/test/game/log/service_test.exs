defmodule Game.Services.LogTest do
  use Test.DBCase, async: true
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Log, LogVisibility}

  setup [:with_game_db]

  describe "list/1 - visible_on_server" do
    test "returns all visible logs from entity on server" do
      %{server: server, entity: entity} = Setup.server()

      visibility_1 = Setup.log_visibility!(entity.id, server_id: server.id)
      visibility_2 = Setup.log_visibility!(entity.id, server_id: server.id)
      _visibility_in_another_server = Setup.log_visibility!(Setup.entity!().id)

      rows = Svc.Log.list_visibility(entity.id, visible_on_server: server.id)

      # Only the two visibilities in `server.id` were found
      assert [visibility_1.log_id.id, visibility_1.revision_id] ==
               Enum.find(rows, &(Enum.at(&1, 0) == visibility_1.log_id.id))

      assert [visibility_2.log_id.id, visibility_2.revision_id] ==
               Enum.find(rows, &(Enum.at(&1, 0) == visibility_2.log_id.id))
    end
  end

  describe "create_new/3" do
    test "inserts the log entry and corresponding visibility" do
      %{server: server, entity: entity} = Setup.server()

      log_params = %{type: :local_login, data: %Log.Data.EmptyData{}}
      assert {:ok, log_1} = Svc.Log.create_new(entity.id, server.id, log_params)
      assert {:ok, log_2} = Svc.Log.create_new(entity.id, server.id, log_params)

      Core.with_context(:server, server.id, :read, fn ->
        logs = DB.all(Log)
        assert log_1 == Enum.find(logs, &(&1.id == log_1.id))
        assert log_2 == Enum.find(logs, &(&1.id == log_2.id))

        # Has the correct data
        assert log_1.server_id == server.id
        assert log_1.type == :local_login
        assert log_1.data == %Log.Data.EmptyData{}

        # It's a brand new log, so revision is always 1
        assert log_1.revision_id == 1

        # Log IDs are sequential
        assert ID.to_external(log_2.id) == ID.to_external(log_1.id) + 1
      end)

      Core.with_context(:player, entity.id, :read, fn ->
        log_visibilities = DB.all(LogVisibility)

        assert visibility_1 = Enum.find(log_visibilities, &(&1.log_id == log_1.id))
        assert _visibility_2 = Enum.find(log_visibilities, &(&1.log_id == log_2.id))

        assert visibility_1.entity_id == entity.id
        assert visibility_1.server_id == server.id
        assert visibility_1.revision_id == 1
      end)
    end
  end
end
