defmodule Game.Endpoint.Server.LoginTest do
  use Test.WebCase, async: true
  alias Core.NIP
  alias Game.{Tunnel, TunnelLink}

  setup [:with_game_db, :with_game_webserver]

  describe "Server.Login request" do
    test "successfully logs into a remote server", %{shard_id: shard_id} = ctx do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{server: gateway, nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{server: endpoint, nip: endp_nip} = Setup.server_full()

      params = %{}

      DB.commit()
      U.start_sse_listener(ctx, player)

      assert {:ok, resp} =
               post(build_path(gtw_nip, endp_nip), params, shard_id: shard_id, token: jwt)

      # A wild Tunnel appears
      begin_game_db()
      assert [tunnel] = DB.all(Tunnel)

      # It has the expected data
      assert tunnel.source_nip == gtw_nip
      assert tunnel.target_nip == endp_nip
      assert tunnel.status == :open
      assert tunnel.access == :ssh

      # TunnelLinks are there, too
      assert [gtw_link, endp_link] =
               DB.all(TunnelLink)
               |> Enum.sort_by(& &1.idx)

      assert gtw_link.tunnel_id == tunnel.id
      assert gtw_link.nip == gtw_nip
      assert gtw_link.idx == 0

      assert endp_link.tunnel_id == tunnel.id
      assert endp_link.nip == endp_nip
      assert endp_link.idx == 1

      # TODO: assert that the connection(group) is there too

      receive do
        {:event, event} ->
          # The client received a `tunnel_created` event
          assert event.name == "tunnel_created"

          # TODO: Maybe I could have an `assert_id`?
          # Which has the expected data
          assert event.data.tunnel_id == tunnel.id.id
          assert event.data.source_nip == gtw_nip |> NIP.to_external()
          assert event.data.target_nip == endp_nip |> NIP.to_external()
          assert event.data.access == "ssh"
      after
        1000 ->
          flunk("No event received")
      end
    end

    # TODO: Test I can't use someone else's server as gateway...
  end

  defp build_path(%NIP{} = source_nip, %NIP{} = target_nip),
    do: "/server/#{NIP.to_external(source_nip)}/login/#{NIP.to_external(target_nip)}"
end
