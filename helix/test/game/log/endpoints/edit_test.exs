defmodule Game.Endpoint.Log.EditTest do
  use Test.WebCase, async: true
  alias Core.{NIP}
  alias Game.{Log, Process, ProcessRegistry}

  setup [:with_game_db, :with_game_webserver]

  describe "Log.Edit request" do
    test "successfully edits a log (Gateway)", %{shard_id: shard_id} do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: gtw_nip} = Setup.server(entity_id: player.id)
      log = Setup.log!(gateway.id, visible_by: player.id)

      DB.commit()

      data =
        %{nip: NIP.to_external(gtw_nip), file_name: "foo", file_ext: "txt", file_version: 10}
        |> Renatils.JSON.encode!()

      params = valid_raw(type: :file_deleted, direction: :to_ap, data: data)

      # Request returns a 200 code with the process ID in it
      assert {:ok, %{status: 200, data: %{process_id: external_process_id}}} =
               post(build_path(gtw_nip, log, player.id), params, shard_id: shard_id, token: jwt)

      # Entry in Game.ProcessRegistry is valid
      Core.with_context(:universe, :read, fn ->
        assert [registry] = DB.all(ProcessRegistry)
        assert registry.process_id == external_process_id |> U.from_eid(player.id)
        assert registry.entity_id.id == player.id.id
        assert registry.server_id == gateway.id
        assert registry.tgt_log_id == log.id
      end)

      # Entry in Game.Process is valid
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [process] = DB.all(Process)
        assert process.id == external_process_id |> U.from_eid(player.id)
        assert process.type == :log_edit
        assert process.server_id == gateway.id
        assert process.entity_id.id == player.id.id
        assert process.data.type == :file_deleted
        assert process.data.direction == :to_ap
        assert process.data.data.file_name == "foo"
        assert process.data.data.file_ext == "txt"
        assert process.data.data.file_version == 10
        assert process.data.data.nip == gtw_nip
        assert process.registry.tgt_log_id == log.id
      end)
    end
  end

  defp valid_raw(opts) do
    opts
    |> valid_params()
    |> Renatils.Map.stringify_keys()
  end

  defp valid_params(opts) do
    # TODO: Make random
    %{
      log_type: opts[:type] || :server_login,
      log_direction: opts[:direction] || :self,
      log_data: opts[:data] || "{}"
    }
  end

  defp build_path(%NIP{} = nip, %Log{} = log, player_id) do
    log_eid = U.to_eid(log.id, player_id, log.server_id)
    "/server/#{NIP.to_external(nip)}/log/#{log_eid}/edit"
  end
end
