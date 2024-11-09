defmodule Game.TunnelTest do
  use Test.DBCase, async: true
  alias Game.Tunnel

  setup [:with_game_db]

  describe "new/1" do
    test "creates a tunnel" do
      source_server = Setup.server_lite!()
      %{nip: source_nip} = Setup.network_connection!(source_server.id, ip: "4.4.4.4")
      assert source_nip.ip == "4.4.4.4"

      target_server = Setup.server_lite!()
      %{nip: target_nip} = Setup.network_connection!(target_server.id, ip: "5.5.5.5")
      assert target_nip.ip == "5.5.5.5"

      assert {:ok, tunnel} =
               %{
                 source_nip: source_nip,
                 target_nip: target_nip,
                 access: :ssh,
                 status: :open
               }
               |> Tunnel.new()
               |> DB.insert()

      assert tunnel.source_nip == source_nip
      assert tunnel.target_nip == target_nip
      assert tunnel.access == :ssh
      assert tunnel.status == :open
    end

    @tag :skip
    test "returns an error if tunnel NIPs are the same" do
      server = Setup.server_lite!()
      %{nip: nip} = Setup.network_connection!(server.id, ip: "4.4.4.4")

      # For now this is TODO. I need to add support for validations in Feeb schemas, and I'd like to
      # have more examples before settling on a validation API.
      %{
        source_nip: nip,
        target_nip: nip,
        access: :ssh,
        status: :open
      }
      |> Tunnel.new()
      |> IO.inspect()
    end
  end
end
