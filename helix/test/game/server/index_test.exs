defmodule Game.Index.ServerTest do
  use Test.DBCase, async: true
  alias Core.NIP
  alias Game.Index

  setup [:with_game_db]

  describe "gateway_index/2" do
    test "returns the expected data" do
      %{nip: nip, entity: entity, server: gateway} = Setup.server()

      assert index = Index.Server.gateway_index(entity.id, gateway)

      # Index contains all the expected keys
      Enum.each(expected_endpoint_keys(), fn key ->
        assert Map.has_key?(index, key)
      end)

      # Keys have the expected values
      assert index.id == gateway.id
      assert index.nip == nip
      assert index.installations == []
      assert index.tunnels == []
      assert index.files == []
      assert index.logs == []
      assert index.processes == []
    end
  end

  describe "render_gateway_index/2" do
    test "returns the rendered version of the index" do
      %{nip: nip, entity: entity, server: gateway} = Setup.server()

      rendered_index =
        entity.id
        |> Index.Server.gateway_index(gateway)
        |> Index.Server.render_gateway_index(entity.id)

      # Rendered index has a client-friendly format
      assert rendered_index.nip == NIP.to_external(nip)
      assert gateway.id == rendered_index.id |> U.from_eid(entity.id)

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Index.Server.endpoint_spec())
    end
  end

  describe "endpoint_index/3" do
    test "returns the expected data" do
      # `entity` has a connection to `endp_nip`
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip)

      assert index = Index.Server.endpoint_index(entity.id, endpoint.id, endp_nip)

      # Index contains all the expected keys
      Enum.each(expected_endpoint_keys(), fn key ->
        assert Map.has_key?(index, key)
      end)

      # Keys have the expected values
      assert index.nip == endp_nip
      assert index.files == []
      assert index.logs == []
      assert index.processes == []
    end
  end

  describe "render_endpoint_index/3" do
    test "returns the rendered version of the index" do
      # `entity` has a connection to `endp_nip`
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{nip: endp_nip, server: endpoint} = Setup.server()
      Setup.tunnel_lite!(source_nip: gtw_nip, target_nip: endp_nip)

      rendered_index =
        entity.id
        |> Index.Server.endpoint_index(endpoint.id, endp_nip)
        |> Index.Server.render_endpoint_index(entity.id)

      # End the transaction early (before the end of the test) because some times this test takes
      # too long to complete and goes beyond the default `feebdb_repo_timeout` of 1s.
      DB.commit()

      # Server ID is *not* returned in the Endpoint index
      refute Map.has_key?(rendered_index, :id)

      # Rendered index has a client-friendly format
      assert rendered_index.nip == NIP.to_external(endp_nip)

      # Rendered index conforms to the Norm contract
      assert {:ok, _} = Norm.conform(rendered_index, Index.Server.endpoint_spec())
    end
  end

  defp expected_endpoint_keys do
    Index.Server.endpoint_spec().schema.specs
    |> Map.keys()
    |> Enum.reject(fn key -> key in [:__openapi_name] end)
  end
end
