defmodule Game.Endpoint.Server.LoginTest do
  use Test.WebCase, async: true
  alias Core.{ID, NIP}
  alias Game.{Tunnel, TunnelLink}

  setup [:with_game_db, :with_game_webserver]

  describe "Server.Login request" do
    # TODO: Note I can easily reproduce the "Adding LS entry to a key that already exists here"
    # But find an easier-to-reproduce / more-minimal example

    test "successfully logs into the endpoint (direct connection)", %{shard_id: shard_id} = ctx do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full()

      params = %{}

      DB.commit()
      U.start_sse_listener(ctx, player)

      assert {:ok, %{status: 200, data: %{}}} =
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

    test "successfully logs into the endpoint (using tunnel)", %{shard_id: shard_id} = ctx do
      # TODO: `player` (and `jwt`?) should automagically show up when `with_game_webserver`
      player = Setup.player!()
      jwt = U.jwt_token(uid: player.external_id)

      %{nip: gtw_nip} = Setup.server_full(entity_id: player.id)
      %{nip: endp_nip} = Setup.server_full()

      %{nip: other_hop_nip} = Setup.server_full()
      %{nip: other_endp_nip} = Setup.server_full()

      # Tunnel between Gateway and OtherEndpoint, which we'll use to create an implicit bounce.
      # Notice it has one intermediary hop. Therefore, we expect the final bounce to be:
      # Gateway -> OtherHop -> OtherEndpoint -> Endpoint
      other_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: other_endp_nip, hops: [other_hop_nip])

      params =
        %{
          tunnel_id: other_tunnel.id |> ID.to_external()
        }

      DB.commit()
      U.start_sse_listener(ctx, player)

      assert {:ok, %{status: 200, data: %{}}} =
               post(build_path(gtw_nip, endp_nip), params, shard_id: shard_id, token: jwt)

      receive do
        {:event, %{name: "tunnel_created", data: %{tunnel_id: raw_tunnel_id}}} ->
          :timer.sleep(300)
          begin_game_db(:read)

          # The tunnel was created as expected
          tunnel_id = Tunnel.ID.from_external(raw_tunnel_id)
          tunnel = Svc.Tunnel.fetch(by_id: tunnel_id)
          assert tunnel.source_nip == gtw_nip
          assert tunnel.target_nip == endp_nip
          assert tunnel.status == :open
          assert tunnel.access == :ssh

          # The tunnel has two intermediary hop: `other_hop` -> `other_tunnel`
          # As expected, the final bounce is: Gateway -> OtherHop -> OtherEndpoint -> Endpoint
          [link_gtw, link_hop_1, link_hop_2, link_endp] =
            Svc.Tunnel.list_links(on_tunnel: tunnel.id)

          assert link_gtw.nip == gtw_nip
          assert link_gtw.idx == 0

          assert link_hop_1.nip == other_hop_nip
          assert link_hop_1.idx == 1

          assert link_hop_2.nip == other_endp_nip
          assert link_hop_2.idx == 2

          assert link_endp.nip == endp_nip
          assert link_endp.idx == 3
      after
        1000 ->
          flunk("No event received")
      end
    end

    @tag :skip
    test "successfully logs into the endpoint (using VPN)", %{shard_id: _shard_id} = _ctx do
    end

    # TODO: Test I can't use someone else's server as gateway...
  end

  defp build_path(%NIP{} = source_nip, %NIP{} = target_nip),
    do: "/server/#{NIP.to_external(source_nip)}/login/#{NIP.to_external(target_nip)}"
end
