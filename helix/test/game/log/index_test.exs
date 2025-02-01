defmodule Game.Index.LogTest do
  use Test.DBCase, async: true
  alias Game.Index

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
      assert [gtw_log_2, gtw_log_1] == Index.Log.index(entity.id, gateway.id)

      # `other_entity` can only see her log
      assert [gtw_log_3] == Index.Log.index(other_entity.id, gateway.id)

      # `entity` cannot see any logs in `other_server`
      assert [] == Index.Log.index(entity.id, other_server.id)

      # `other_entity` can see her only log in her gateway
      assert [other_log_1] == Index.Log.index(other_entity.id, other_server.id)
    end

    test "handles scenario where player has access to multiple revisions from the same log" do
      %{server: gateway, entity: entity} = Setup.server()

      rev_1 = Setup.log!(gateway.id, visible_by: entity.id)
      rev_2 = Setup.log!(gateway.id, id: rev_1.id, revision_id: 2, visible_by: entity.id)

      # These are two revisions of the same log
      assert rev_1.id == rev_2.id
      assert rev_1.revision_id.id == 1
      assert rev_2.revision_id.id == 2

      # The index only returned `rev_2`
      assert [rev_2] == Index.Log.index(entity.id, gateway.id)

      # NOTE/TODO: In the future, I will certainly want to send every revision a player has access
      # to as part of the bootstrap, so that the Client can render the "revision history". For now,
      # I'm ignoring this, but I might need to change the index structure (or underlying query) to
      # handle this scenario.
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
      assert log_1.revision_id == gtw_log_1.revision_id.id
      assert log_2.revision_id == gtw_log_2.revision_id.id
      assert log_1.type == "#{gtw_log_1.type}"
      assert log_2.type == "#{gtw_log_1.type}"

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Norm.coll_of(Index.Log.spec()))
    end
  end
end
