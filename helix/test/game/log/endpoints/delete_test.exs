defmodule Game.Endpoint.Log.DeleteTest do
  use Test.WebCase, async: true
  alias Game.{Log}

  setup [:with_game_db, :with_game_webserver]

  describe "Log.Delete request" do
    test "successfully starts a LogDeleteProcess (gateway)" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      log = Setup.log!(gateway.id, visible_by: player.id)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(nip, log, player.id), %{}, token: jwt)

      assert data.process.process_id
      assert data.process.type == "log_delete"
      assert data.log_id == log.id |> U.to_eid(player.id)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id
      assert registry.tgt_log_id == log.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :log_delete
      assert process.data.log_id == log.id
      assert process.registry.tgt_log_id == log.id
    end

    test "successfully starts a LogDeleteProcess (endpoint)" do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      # There is a Tunnel from Gateway -> Endpoint
      %{nip: gtw_nip, server: gateway} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      # Log exists in the Endpoint and is visible by the Player
      log = Setup.log!(endpoint.id, visible_by: player.id)
      DB.commit()

      params = %{tunnel_id: tunnel.id |> U.to_eid(player.id)}

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(endp_nip, log, player.id), params, token: jwt)

      assert data.process.process_id
      assert data.process.type == "log_delete"
      assert data.log_id == log.id |> U.to_eid(player.id)

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == endpoint.id
      assert registry.tgt_log_id == log.id

      # No processes were created in the Gateway
      assert [] = U.get_all_processes(gateway.id)

      # But there is a new process in the Endpoint
      assert [_] = U.get_all_processes(endpoint.id)
    end

    test "returns an error if log is in another server" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: nip} = Setup.server_full(entity_id: player.id)
      # The log exists and is visible by the player, but in a different server
      log = Setup.log!(Setup.server!().id, visible_by: player.id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, log, player.id), %{}, token: jwt)

      assert reason == "log_not_found"
    end

    test "returns an error if player does not have visibility over log" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      # The log exists in the Gateway but it isn't visible by the player
      log = Setup.log!(gateway.id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, log, player.id), %{}, token: jwt)

      assert reason == "log_not_found"
    end

    test "returns an error if log is already deleted" do
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: nip} = Setup.server_full(entity_id: player.id)
      log = Setup.log!(gateway.id, visible_by: player.id, is_deleted: true)
      assert log.is_deleted
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(nip, log, player.id), %{}, token: jwt)

      assert reason == "log_already_deleted"
    end
  end

  defp build_path(%NIP{} = nip, %Log{} = log, player_id) do
    log_eid = ID.to_external(log.id, player_id, log.server_id)
    "/server/#{NIP.to_external(nip)}/log/#{log_eid}/delete"
  end
end
