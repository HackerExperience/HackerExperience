defmodule Core.EndpointTest do
  use Test.DBCase, async: true
  alias Core.Endpoint

  setup [:with_game_db]

  describe "cast_id/4" do
    test "casts the ID accordingly" do
      %{server: server, entity: entity} = Setup.server()
      file = Setup.file!(server.id)

      server_eid = U.to_eid(server.id, entity.id)
      file_eid = U.to_eid(file.id, entity.id, server.id)
      put_entity_in_process(entity.id)

      assert {:ok, server.id} == Endpoint.cast_id(:field, server_eid, Game.Server)
      assert {:ok, file.id} == Endpoint.cast_id(:field, file_eid, Game.File)

      # When the external ID is not found, it returns the :id_not_found error
      assert {:error, {:field, :id_not_found}} == Endpoint.cast_id(:field, Random.uuid(), Game.File)
      assert {:error, {:field, :id_not_found}} == Endpoint.cast_id(:field, "not_an_uuid", Game.File)
      assert {:error, {:field, :id_not_found}} == Endpoint.cast_id(:field, "", Game.File)

      # When no external ID is passed, it returns the :empty error
      assert {:error, {:field, :empty}} == Endpoint.cast_id(:field, nil, Game.Tunnel)

      # When an unexpected data type is passed, it returns the :invalid error
      assert {:error, {:field, :invalid}} == Endpoint.cast_id(:field, 1.0, Game.Log)
      assert {:error, {:field, :invalid}} == Endpoint.cast_id(:field, 10, Game.Log)
      assert {:error, {:field, :invalid}} == Endpoint.cast_id(:field, {1, 2}, Game.Log)
      assert {:error, {:field, :invalid}} == Endpoint.cast_id(:field, :abc, Game.Log)
      assert {:error, {:field, :invalid}} == Endpoint.cast_id(:field, ["a"], Game.Log)
    end

    test "does not return an error if the ID is null and it is optional" do
      put_entity_in_process(Setup.entity!().id)
      assert {:ok, nil} == Endpoint.cast_id(:field, nil, Game.Server, optional: true)
    end

    test "returns an error if the external ID belongs to a different object" do
      %{server: server, entity: entity} = Setup.server()
      file = Setup.file!(server.id)

      server_eid = U.to_eid(server.id, entity.id)
      file_eid = U.to_eid(file.id, entity.id, server.id)
      put_entity_in_process(entity.id)

      # I'm passing the external ID for my file in a field that was expecting a Server external ID
      assert {:error, {:field, :id_not_found}} = Endpoint.cast_id(:field, file_eid, Game.Server)

      # But it works if I pass in the correct external ID
      assert {:ok, server.id} == Endpoint.cast_id(:field, server_eid, Game.Server)
    end
  end

  defp put_entity_in_process(entity_id) do
    Process.put(:helix_session_entity_id, entity_id)
  end
end
