defmodule Core.ID.ExternalTest do
  use Test.DBCase, async: true

  alias Core.ID
  alias Game.ExternalID

  setup [:with_game_db]

  describe "to_external/2" do
    test "creates an external only once for the same unique object" do
      %{server: server, entity: entity} = Setup.server()
      file = Setup.file!(server.id)

      file_internal_identifier = {file.id.id, :file_id, server.id.id, nil}

      # Initially there are no stored ExternalIDs in the database
      Core.with_context(:player, entity.id, :read, fn ->
        assert [] == DB.all(ExternalID)
      end)

      file_eid = ID.External.to_external(entity.id, file_internal_identifier)
      assert is_binary(file_eid)

      # Now we have 1 entry
      Core.with_context(:player, entity.id, :read, fn ->
        assert [_] = DB.all(ExternalID)
      end)

      # When calling `to_external/2` again with the same set of {entity_id, object_identifier},
      # we get the same ID
      assert file_eid == ID.External.to_external(entity.id, file_internal_identifier)
      assert file_eid == ID.External.to_external(entity.id, file_internal_identifier)
      assert file_eid == ID.External.to_external(entity.id, file_internal_identifier)

      # If we try to get the external ID of the same object to a different player, we get a
      # different external ID
      other_player = Setup.player!()
      refute file_eid == ID.External.to_external(other_player.id, file_internal_identifier)

      # Still one entry for the first `entity`
      Core.with_context(:player, entity.id, :read, fn ->
        assert [_] = DB.all(ExternalID)
      end)

      # But now we have 1 entry for `other_player`
      Core.with_context(:player, other_player.id, :read, fn ->
        assert [_] = DB.all(ExternalID)
      end)
    end
  end

  describe "from_external/2" do
    test "returns the object ID when the external ID is a match (returns nil otherwise)" do
      %{server: server, entity: entity} = Setup.server()
      file = Setup.file!(server.id)
      internal_identifier = {file.id.id, :file_id, server.id.id, nil}
      file_eid = ID.External.to_external(entity.id, internal_identifier)

      # We always get the `file.id` back, exactly as it was originally
      assert file.id == ID.External.from_external(file_eid, entity.id)
      assert file.id == ID.External.from_external(file_eid, entity.id)
      assert file.id == ID.External.from_external(file_eid, entity.id)

      # A different player can't get this ID
      refute ID.External.from_external(file_eid, Setup.player!().id)
    end
  end
end
