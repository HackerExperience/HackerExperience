defmodule Game.Endpoint.Scanner.EditTest do
  use Test.WebCase, async: true
  alias Core.{NIP}
  alias Game.{Process, ProcessRegistry, ScannerInstance}

  alias Game.Scanner.Params.Connection, as: ConnParams
  alias Game.Scanner.Params.Log, as: LogParams

  setup [:with_game_db, :with_game_webserver]

  describe "Scanner.Edit request" do
    test "successfully edits a ScannerInstance (Gateway)", %{jwt: jwt, player: player} do
      %{server: server, nip: nip, entity: entity} = Setup.server(entity_id: player.id)

      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      log_instance = Enum.find(instances, &(&1.type == :log))

      DB.commit()

      target_params =
        %{"type" => "custom", "direction" => "self"}
        |> JSON.encode!()

      params = valid_raw(type: :log, target_params: target_params)

      # Request returns a 200 code with the process ID in it
      assert {:ok, %{status: 200, data: %{process_id: external_process_id}}} =
               post(build_path(nip, log_instance.id, player.id), params, token: jwt)

      # Entry in Game.ProcessRegistry is valid
      Core.with_context(:universe, :read, fn ->
        assert [registry] = DB.all(ProcessRegistry)
        assert registry.process_id == external_process_id |> U.from_eid(player.id)
        assert registry.entity_id.id == player.id.id
        assert registry.server_id == server.id
      end)

      # Entry in Game.Process is valid
      Core.with_context(:server, server.id, :read, fn ->
        assert [process] = DB.all(Process)
        assert process.id == external_process_id |> U.from_eid(player.id)
        assert process.type == :scanner_edit
        assert process.server_id == server.id
        assert process.entity_id.id == player.id.id
        assert process.data.instance_id == log_instance.id
        assert process.data.target_params.__struct__ == LogParams
        assert process.data.target_params.direction == :self
        assert process.data.target_params.type == :custom
        assert process.data.target_params.date_from == nil
        assert process.data.target_params.date_to == nil
      end)
    end

    test "successfuly edits a ScannerInstance (Endpoint)", %{jwt: jwt, player: player} do
      %{nip: gtw_nip, entity: entity} = Setup.server(entity_id: player.id)
      %{server: endpoint, nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      instances =
        Setup.scanner_instances!(entity_id: entity.id, server_id: endpoint.id, tunnel_id: tunnel.id)

      conn_instance = Enum.find(instances, &(&1.type == :connection))

      DB.commit()

      params = valid_raw(type: :connection, tunnel_id: tunnel.id |> U.to_eid(player.id))

      # Request returns a 200 code with the process ID in it
      assert {:ok, %{status: 200, data: %{process_id: external_process_id}}} =
               post(build_path(endp_nip, conn_instance.id, player.id), params, token: jwt)

      # Entry in Game.ProcessRegistry is valid
      Core.with_context(:universe, :read, fn ->
        assert [registry] = DB.all(ProcessRegistry)
        assert registry.process_id == external_process_id |> U.from_eid(player.id)
        assert registry.entity_id.id == player.id.id
        assert registry.server_id == endpoint.id
      end)

      # Entry in Game.Process is valid
      Core.with_context(:server, endpoint.id, :read, fn ->
        assert [process] = DB.all(Process)
        assert process.id == external_process_id |> U.from_eid(player.id)
        assert process.type == :scanner_edit
        assert process.server_id == endpoint.id
        assert process.entity_id.id == player.id.id
        assert process.data.instance_id == conn_instance.id
        assert process.data.target_params.__struct__ == ConnParams
      end)
    end

    @tag :capture_log
    test "fails if target_params are invalid", %{jwt: jwt, player: player} do
      %{server: server, nip: nip, entity: entity} = Setup.server(entity_id: player.id)
      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      DB.commit()

      [
        # Invalid type
        {:log, %{"type" => nil, "direction" => "hop"}},
        # Invalid pairing
        {:log, %{"type" => "connection_proxied", "direction" => "self"}}
      ]
      |> Enum.each(fn {instance_type, target_params} ->
        params = valid_raw(type: instance_type, target_params: JSON.encode!(target_params))

        instance = Enum.find(instances, &(&1.type == instance_type))

        assert {:error, %{status: 400, error: %{msg: error}}} =
                 post(build_path(nip, instance.id, player.id), params, token: jwt)

        assert error == "target_params:invalid_input"
      end)
    end

    test "fails upon instance_type mismatch", %{jwt: jwt, player: player} do
      %{server: server, nip: nip, entity: entity} = Setup.server(entity_id: player.id)
      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      file_instance = Enum.find(instances, &(&1.type == :file))
      DB.commit()

      # We are passing valid log params... for a file ScannerInstance
      target_params =
        %{"type" => "custom", "direction" => "self"}
        |> JSON.encode!()

      params = valid_raw(type: :log, target_params: target_params)

      assert {:error, %{status: 400, error: %{msg: error_msg}}} =
               post(build_path(nip, file_instance.id, player.id), params, token: jwt)

      assert error_msg == "instance_invalid_params"
    end

    test "fails when updating a instance that doesn't exist", %{jwt: jwt, player: player} do
      %{nip: nip} = Setup.server(entity_id: player.id)

      # There are no instances for this server

      DB.commit()

      params = valid_raw(type: :connection)

      assert {:error, %{status: 400, error: %{msg: error_msg}}} =
               post(build_path(nip, R.scanner_instance_id(), player.id), params, token: jwt)

      assert error_msg == "instance_not_found"
    end

    test "fails when attempting to update someone else's instance", %{jwt: jwt, player: player} do
      %{nip: my_nip, entity: my_entity} = Setup.server(entity_id: player.id)
      %{server: other_server, entity: other_entity} = Setup.server()

      refute my_entity.id == other_entity.id

      [other_instance | _] =
        Setup.scanner_instances!(entity_id: other_entity.id, server_id: other_server.id)

      assert other_instance.entity_id == other_entity.id

      DB.commit()

      params = valid_raw(type: other_instance.type)

      assert {:error, %{status: 400, error: %{msg: error_msg}}} =
               post(build_path(my_nip, other_instance.id, player.id), params, token: jwt)

      assert error_msg == "instance_not_found"
    end

    # test: valid but with no tunnel access
  end

  defp valid_raw(opts) do
    opts
    |> valid_params()
    |> Renatils.Map.stringify_keys()
  end

  defp valid_params(opts) do
    %{
      instance_type: opts[:type] || :log,
      target_params: opts[:target_params] || "{}",
      tunnel_id: opts[:tunnel_id]
    }
  end

  defp build_path(%NIP{} = nip, %ScannerInstance.ID{} = instance_id, player_id) do
    instance_eid = U.to_eid(instance_id, player_id)
    "/server/#{NIP.to_external(nip)}/scanner/#{instance_eid}/edit"
  end
end
