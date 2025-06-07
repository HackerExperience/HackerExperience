defmodule Game.Services.LogTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc
  alias Game.{Log}

  setup [:with_game_db]

  describe "fetch_visibility/3 - :by_log" do
    test "returns the visibility if the log is visible" do
      %{server: server, entity: entity} = Setup.server()

      # `entity` can see `log`, so the visibility is returned
      %{log: log, log_visibility: visibility} = Setup.log(server.id, visible_by: entity.id)
      assert visibility == Svc.Log.fetch_visibility(entity.id, by_log: log)

      # `entity` can't see `other_log`; nothing is returned
      other_log = Setup.log!(server.id)
      refute Svc.Log.fetch_visibility(entity.id, by_log: other_log)
    end
  end

  describe "list_visibility/3 - visible_on_server" do
    test "returns all visible logs from entity on server" do
      %{server: server, entity: entity} = Setup.server()

      visibility_1 = Setup.log_visibility!(entity.id, server_id: server.id)
      visibility_2 = Setup.log_visibility!(entity.id, server_id: server.id)
      _visibility_in_another_server = Setup.log_visibility!(Setup.entity!().id)

      rows = Svc.Log.list_visibility(entity.id, visible_on_server: server.id)

      # Only the two visibilities in `server.id` were found
      assert [visibility_1.log_id.id, visibility_1.revision_id.id] ==
               Enum.find(rows, &(Enum.at(&1, 0) == visibility_1.log_id.id))

      assert [visibility_2.log_id.id, visibility_2.revision_id.id] ==
               Enum.find(rows, &(Enum.at(&1, 0) == visibility_2.log_id.id))
    end
  end

  describe "create_new/3" do
    test "inserts the log entry and corresponding visibility" do
      %{server: server, entity: entity} = Setup.server()

      log_params = %{type: :server_login, direction: :self, data: %Log.Data.EmptyData{}}
      assert {:ok, log_1} = Svc.Log.create_new(entity.id, server.id, log_params)
      assert {:ok, log_2} = Svc.Log.create_new(entity.id, server.id, log_params)

      logs = U.get_all_logs(server.id)
      assert log_1 == Enum.find(logs, &(&1.id == log_1.id))
      assert log_2 == Enum.find(logs, &(&1.id == log_2.id))

      # Has the correct data
      assert log_1.server_id == server.id
      assert log_1.type == :server_login
      assert log_1.direction == :self
      assert log_1.data == %Log.Data.EmptyData{}

      # It's a brand new log, so revision is always 1
      assert log_1.revision_id.id == 1

      # (Internal) Log IDs are sequential
      assert log_2.id.id == log_1.id.id + 1

      # Visibilities were inserted correctly
      log_visibilities = U.get_all_log_visibilities(entity.id)

      assert visibility_1 = Enum.find(log_visibilities, &(&1.log_id == log_1.id))
      assert _visibility_2 = Enum.find(log_visibilities, &(&1.log_id == log_2.id))

      assert visibility_1.entity_id == entity.id
      assert visibility_1.server_id == server.id
      assert visibility_1.revision_id.id == 1
    end
  end

  describe "create_revision/4" do
    test "creates a new revision and the corresponding visibility" do
      %{server: server, entity: entity} = Setup.server()

      log_params = %{type: :server_login, direction: :self, data: %Log.Data.EmptyData{}}

      log = Setup.log!(server.id, visible_by: entity.id)
      assert log.revision_id.id == 1

      assert {:ok, rev_2} = Svc.Log.create_revision(entity.id, server.id, log.id, log_params)
      assert {:ok, rev_3} = Svc.Log.create_revision(entity.id, server.id, log.id, log_params)

      assert rev_2.id == log.id
      assert rev_2.revision_id.id == 2
      assert rev_2.type == :server_login
      assert rev_2.direction == :self
      assert rev_2.data == %Log.Data.EmptyData{}

      assert rev_3.id == log.id
      assert rev_3.revision_id.id == 3

      log_visibilities = U.get_all_log_visibilities(entity.id)
      assert visibility_2 = Enum.find(log_visibilities, &(&1.revision_id.id == 2))
      assert visibility_3 = Enum.find(log_visibilities, &(&1.revision_id.id == 3))

      assert visibility_2.log_id == log.id
      assert visibility_2.entity_id == entity.id
      assert visibility_2.server_id == server.id

      assert visibility_3.log_id == log.id
      assert visibility_3.entity_id == entity.id
      assert visibility_3.server_id == server.id
    end
  end

  describe "delete/2" do
    test "deletes a log and all its revisions" do
      %{server: server, entity: entity} = Setup.server()

      log_rev_1 = Setup.log!(server.id, visible_by: entity.id)
      log_rev_2 = Setup.log!(server.id, id: log_rev_1.id, revision_id: 2, visible_by: entity.id)
      other_log = Setup.log!(server.id, visible_by: entity.id)

      Core.begin_context(:server, server.id, :read)

      # Delete the log (and all its revisions)
      assert :ok == Svc.Log.delete(log_rev_2, entity.id)

      # Both revisions were flagged as deleted
      log_rev_1 = DB.reload(log_rev_1)
      assert log_rev_1.is_deleted
      assert log_rev_1.deleted_at
      assert log_rev_1.deleted_by == entity.id

      log_rev_2 = DB.reload(log_rev_2)
      assert log_rev_2.is_deleted
      assert log_rev_2.deleted_at == log_rev_1.deleted_at
      assert log_rev_2.deleted_by == entity.id

      # `other_log` remains unchanged
      other_log = DB.reload(other_log)
      refute other_log.is_deleted
    end
  end
end
