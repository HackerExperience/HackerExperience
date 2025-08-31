defmodule Game.Endpoint.Server.LoginTest do
  use Test.WebCase, async: true
  alias Core.{ID, NIP}

  setup [:with_game_db, :with_game_webserver]

  describe "Server.Login request" do
    test "starts a ServerLoginProcess (direct connection)", %{jwt: jwt, player: player} do
      %{server: gateway, nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()
      DB.commit()

      params = %{}

      assert {:ok, %{status: 200, data: %{process_id: process_eid}}} =
               post(build_path(gtw_nip, endp_nip), params, token: jwt)

      # A ServerLoginProcess was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == process_eid |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :server_login
      assert process.data.source_nip == gtw_nip
      assert process.data.target_nip == endp_nip
      refute process.data.tunnel_id
      refute process.data.vpn_id
    end

    test "starts a ServerLoginProcess (using Tunnel)", %{jwt: jwt, player: player} do
      %{server: gateway, nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip} = Setup.server()

      %{nip: other_hop_nip} = Setup.server()
      %{nip: other_endp_nip} = Setup.server()

      # Tunnel between Gateway and OtherEndpoint, which we'll use to create an implicit bounce.
      # Notice it has one intermediary hop. Therefore, we expect the final bounce to be:
      # Gateway -> OtherHop -> OtherEndpoint -> Endpoint
      other_tunnel =
        Setup.tunnel!(source_nip: gtw_nip, target_nip: other_endp_nip, hops: [other_hop_nip])

      DB.commit()

      params = %{tunnel_id: other_tunnel.id |> U.to_eid(player.id)}

      assert {:ok, %{status: 200, data: %{process_id: process_eid}}} =
               post(build_path(gtw_nip, endp_nip), params, token: jwt)

      # A ServerLoginProcess was created
      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == process_eid |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == gateway.id

      assert [process] = U.get_all_processes(gateway.id)
      assert process.type == :server_login
      assert process.data.source_nip == gtw_nip
      assert process.data.target_nip == endp_nip
      assert process.data.tunnel_id == other_tunnel.id
      refute process.data.vpn_id
    end

    @tag :skip
    test "starts a ServerLoginProcess (using VPN)" do
    end

    test "can't use someone else's server as gateway", %{jwt: jwt, player: player} do
      %{server: other_server, nip: other_nip} = Setup.server()
      %{nip: endp_nip} = Setup.server()
      DB.commit()

      # The `other_server` belongs to a different user entirely
      refute other_server.entity_id.id == player.id

      # We can't create an OtherServer -> Endpoint connection because OtherServer is not a valid
      # gateway for `player`
      assert {:error, %{status: 400, error: %{msg: "invalid_gateway"}}} =
               post(build_path(other_nip, endp_nip), %{}, token: jwt)
    end

    test "fails if gateway NIP does not exist", %{jwt: jwt} do
      %{nip: endp_nip} = Setup.server()
      DB.commit()

      random_nip = R.nip()

      assert {:error, %{status: 400, error: %{msg: "invalid_gateway"}}} =
               post(build_path(random_nip, endp_nip), %{}, token: jwt)
    end

    test "fails if tunnel does not exist", %{jwt: jwt, player: player} do
      %{nip: nip} = Setup.server(entity_id: player.id)
      DB.commit()

      params = %{tunnel_id: Random.uuid()}

      # We can't create an SSH connection using a Tunnel that does not exist
      assert {:error, %{status: 400, error: %{msg: "tunnel_id:id_not_found"}}} =
               post(build_path(nip, nip), params, token: jwt)
    end

    test "fails if tunnel belongs to someone else", %{jwt: jwt} do
      player = Setup.player!()
      other_player = Setup.player!()

      %{nip: gtw_nip} = Setup.server(entity_id: player.id)
      %{nip: endp_nip, server: endpoint} = Setup.server(entity_id: other_player.id)
      %{nip: other_nip} = Setup.server()

      # There is a tunnel from Endpoint -> Other that belongs to OtherPlayer
      other_tunnel = Setup.tunnel!(source_nip: endp_nip, target_nip: other_nip)
      DB.commit()

      params = %{tunnel_id: other_tunnel.id |> ID.to_external(other_player.id, endpoint.id)}

      # We can't create an SSH connection using a Tunnel that is not ours
      assert {:error, %{status: 400, error: %{msg: "tunnel_id:id_not_found"}}} =
               post(build_path(gtw_nip, endp_nip), params, token: jwt)
    end

    test "fails if NIPs are invalid", %{jwt: jwt} do
      params = %{}
      DB.commit()

      invalid_nips =
        [
          "",
          "not_an_ip",
          "0@123",
          "0@1.1.1.1%20",
          "%200@1.1.1.1",
          "0@1.1.1.1@0",
          "1.1.1.1",
          "256.50.256.50",
          "128.128.-1.128",
          "1.1"
        ]

      # First round, testing the gateway NIP
      Enum.each(invalid_nips, fn src_nip ->
        assert {:error, %{status: 400, error: %{msg: "nip:invalid_nip"}}} =
                 post("/server/#{src_nip}/login/0@2.2.2.2", params, token: jwt)
      end)

      # Second round, testing the endpoint NIP
      Enum.each(invalid_nips, fn
        "" ->
          :this_will_cause_a_404_out_of_scope

        tgt ->
          assert {:error, %{status: 400, error: %{msg: "target_nip:invalid_nip"}}} =
                   post("/server/0@3.3.3.3/login/#{tgt}", params, token: jwt)
      end)
    end

    test "fails if tunnel_id is invalid", %{jwt: jwt} do
      DB.commit()

      [
        "",
        "-1",
        "91mid",
        "10%20",
        "1+1",
        "not_an_id",
        "; DROP TABLE users; --"
      ]
      |> Enum.each(fn invalid_tunnel_id ->
        params = %{tunnel_id: invalid_tunnel_id}

        assert {:error, %{status: 400, error: %{msg: "tunnel_id:id_not_found"}}} =
                 post("/server/0@1.1.1.1/login/0@2.2.2.2", params, token: jwt)
      end)
    end
  end

  defp build_path(%NIP{} = source_nip, %NIP{} = target_nip),
    do: "/server/#{NIP.to_external(source_nip)}/login/#{NIP.to_external(target_nip)}"
end
