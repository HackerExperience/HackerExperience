defmodule Game.Endpoint.Log.EditTest do
  use Test.WebCase, async: true
  alias Core.{NIP}
  alias Game.{Log, Process, ProcessRegistry}

  setup [:with_game_db, :with_game_webserver]

  describe "Log.Edit request" do
    test "successfully edits a log (Gateway)", %{shard_id: shard_id} = ctx do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: gtw_nip} = Setup.server(entity_id: player.id)
      log = Setup.log!(gateway.id)

      DB.commit()
      U.start_sse_listener(ctx, player)

      params = %{
        foo: :bar
      }

      # Request returns a 200 code with the process ID in it
      assert {:ok, %{status: 200, data: %{process_id: external_process_id}}} =
               post(build_path(gtw_nip, log.id), params, shard_id: shard_id, token: jwt)

      # Entry in Game.ProcessRegistry is valid
      Core.with_context(:universe, :read, fn ->
        assert [registry] = DB.all(ProcessRegistry)
        assert registry.process_id.id == external_process_id
        assert registry.entity_id.id == player.id.id
        assert registry.server_id == gateway.id
        assert registry.tgt_log_id == log.id
      end)

      # Entry in Game.Process is valid
      Core.with_context(:server, gateway.id, :read, fn ->
        assert [process] = DB.all(Process)
        assert process.id.id == external_process_id
        assert process.type == :log_edit
        assert process.server_id == gateway.id
        assert process.entity_id.id == player.id.id
        assert process.data.log_type == :server_login
        assert process.data.log_direction == :self
        assert process.data.log_data == %{}
        assert process.registry.tgt_log_id == log.id
      end)

      # TODO: Once implemented, test that the log actually got edited

      receive do
        {:event, event} ->
          assert event.name == "process_created"
          assert event.data.id == external_process_id
          assert event.data.type == "log_edit"
      after
        1000 ->
          flunk("No event received")
      end
    end
  end

  defp build_path(%NIP{} = nip, %Log.ID{id: raw_log_id}),
    do: "/server/#{NIP.to_external(nip)}/log/#{raw_log_id}/edit"
end
