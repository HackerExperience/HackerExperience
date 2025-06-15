defmodule Game.Index.LogTest do
  use Test.DBCase, async: true
  alias Game.Index
  alias Game.Log.Data, as: LogData

  setup [:with_game_db]

  describe "index/2" do
    test "returns all visible logs from entity on server" do
      %{server: gateway, entity: entity} = Setup.server()
      %{server: other_server, entity: other_entity} = Setup.server()

      # `entity` has two logs visible in `gateway`, while `other_entity` has one
      # Order matters, hence the explicit IDs.
      gtw_log_1 = Setup.log!(gateway.id, id: 1, visible_by: entity.id)
      gtw_log_2 = Setup.log!(gateway.id, id: 2, visible_by: entity.id)
      gtw_log_3 = Setup.log!(gateway.id, id: 3, visible_by: other_entity.id)

      # `entity` has no visible logs in `other_server`, while `other_entity` has only one
      other_log_1 = Setup.log!(other_server.id, id: 1, visible_by: other_entity.id)
      _other_log_2 = Setup.log!(other_server.id, id: 2)

      # `entity` can see both logs, but won't see log from other entity. Order is correct
      assert [{2, [{gtw_log_2, 1, "self"}]}, {1, [{gtw_log_1, 1, "self"}]}] ==
               Index.Log.index(entity.id, gateway.id)

      # `other_entity` can only see her log
      assert [{3, [{gtw_log_3, 1, "self"}]}] == Index.Log.index(other_entity.id, gateway.id)

      # `entity` cannot see any logs in `other_server`
      assert [] == Index.Log.index(entity.id, other_server.id)

      # `other_entity` can see her only log in her gateway
      assert [{1, [{other_log_1, 1, "self"}]}] == Index.Log.index(other_entity.id, other_server.id)
    end

    test "handles scenario where player has access to multiple revisions from the same log" do
      %{server: gateway, entity: entity} = Setup.server()

      # Log 1 has two revisions (1 and 2), both of which are visible by `entity`
      log_1 = Setup.log!(gateway.id, id: 1, revision_id: 1, visible_by: entity.id)
      log_1_rev_2 = Setup.log!(gateway.id, id: log_1.id, revision_id: 2, visible_by: entity.id)

      # Log 2 has five revisions (1-5), but `entity` only has visibility on revisions 3 and 4
      log_2 = Setup.log!(gateway.id, id: 2, revision_id: 1)
      _log_2_rev_2 = Setup.log!(gateway.id, id: log_2.id, revision_id: 2)
      log_2_rev_3 = Setup.log!(gateway.id, id: log_2.id, revision_id: 3, visible_by: entity.id)
      log_2_rev_4 = Setup.log!(gateway.id, id: log_2.id, revision_id: 4, visible_by: entity.id)
      _log_2_rev_5 = Setup.log!(gateway.id, id: log_2.id, revision_id: 5)

      # Log 2 comes first because it is older than log 1
      assert [{log_2_raw_id, log_2_entries}, {log_1_raw_id, log_1_entries}] =
               Index.Log.index(entity.id, gateway.id)

      # We got back revisions 4 and 3 from log 2, which correspond to personal revisions 2 and 1
      assert log_2_raw_id == log_2.id.id
      assert [{log_2_rev_4, 2, "self"}, {log_2_rev_3, 1, "self"}] == log_2_entries

      # We got back revisions 2 and 1 from log 1, which correspond to personal revisions 2 and 1
      assert log_1_raw_id == log_1.id.id
      assert [{log_1_rev_2, 2, "self"}, {log_1, 1, "self"}] == log_1_entries
    end
  end

  describe "render_index/1" do
    test "output conforms to the Norm contract" do
      %{server: gateway, entity: entity} = Setup.server()

      gtw_log_1 = Setup.log!(gateway.id, id: 1, visible_by: entity.id)
      gtw_log_2 = Setup.log!(gateway.id, id: 2, visible_by: entity.id)

      rendered_index =
        entity.id
        |> Index.Log.index(gateway.id)
        |> Index.Log.render_index(entity.id)

      # Rendered index contains log information we need
      assert [log_2, log_1] = rendered_index

      assert log_1.id |> U.from_eid(entity.id) == gtw_log_1.id
      assert log_2.id |> U.from_eid(entity.id) == gtw_log_2.id

      assert log_1.revision_count == 1
      assert log_2.revision_count == 1

      assert [log_1_revision] = log_1.revisions
      assert [log_2_revision] = log_2.revisions

      assert log_1_revision.type == "#{gtw_log_1.type}"
      assert log_2_revision.type == "#{gtw_log_2.type}"

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Norm.coll_of(Index.Log.spec()))
    end

    test "handles scenario where player has access to multiple revisions from the same log" do
      %{server: gateway, entity: entity} = Setup.server()

      # Log 1 has two revisions (1 and 2), both of which are visible by `entity`
      log_1 = Setup.log!(gateway.id, id: 1, revision_id: 1, visible_by: entity.id)
      _log_1_rev_2 = Setup.log!(gateway.id, id: log_1.id, revision_id: 2, visible_by: entity.id)

      # Log 2 has five revisions (1-5), but `entity` only has visibility on revisions 3 and 4
      log_2 = Setup.log!(gateway.id, id: 2, revision_id: 1)
      _log_2_rev_2 = Setup.log!(gateway.id, id: log_2.id, revision_id: 2)
      _log_2_rev_3 = Setup.log!(gateway.id, id: log_2.id, revision_id: 3, visible_by: entity.id)
      _log_2_rev_4 = Setup.log!(gateway.id, id: log_2.id, revision_id: 4, visible_by: entity.id)
      _log_2_rev_5 = Setup.log!(gateway.id, id: log_2.id, revision_id: 5)

      rendered_index =
        entity.id
        |> Index.Log.index(gateway.id)
        |> Index.Log.render_index(entity.id)

      assert [rendered_log_2, rendered_log_1] = rendered_index

      assert log_2.id == rendered_log_2.id |> U.from_eid(entity.id)
      refute rendered_log_2.is_deleted
      assert rendered_log_2.revision_count == 2

      # Both revisions for Log 2 were returned with the personal revision counter
      assert [rendered_log_2_personal_rev_2, rendered_log_2_personal_rev_1] =
               rendered_log_2.revisions

      assert rendered_log_2_personal_rev_2.revision_id == 2
      assert rendered_log_2_personal_rev_1.revision_id == 1

      # Same thing for Log 1: it was returned with the personal revisions scoped to the entity
      assert [rendered_log_1_personal_rev_2, rendered_log_1_personal_rev_1] =
               rendered_log_1.revisions

      assert rendered_log_1_personal_rev_2.revision_id == 2
      assert rendered_log_1_personal_rev_1.revision_id == 1

      assert rendered_log_1.sort_strategy == "newest_first"
      assert rendered_log_2.sort_strategy == "newest_first"

      # Rendered index conforms to the Norm spec
      assert {:ok, _} = Norm.conform(rendered_index, Norm.coll_of(Index.Log.spec()))
    end

    test "renders the log data accordingly" do
      %{server: server, nip: nip, entity: entity} = Setup.server()

      Setup.log!(server.id,
        type: :server_login,
        direction: :to_ap,
        data: %LogData.NIP{nip: nip},
        visible_by: entity.id
      )

      rendered_index =
        entity.id
        |> Index.Log.index(server.id)
        |> Index.Log.render_index(entity.id)

      assert [%{revisions: [revision]}] = rendered_index
      assert revision.type == "server_login"
      assert revision.direction == "to_ap"
      assert revision.data == "{\"nip\":\"#{NIP.to_external(nip)}\"}"
    end
  end
end
