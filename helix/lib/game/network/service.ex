defmodule Game.Services.Network do
  alias Game.Services, as: Svc
  alias Game.{Tunnel}

  def resolve_bounce_hops(%Tunnel{} = tunnel) do
    # Get all intermediary hops in a tunnel
    links = Svc.Tunnel.list_links(on_tunnel: tunnel.id)

    # The first link is the gateway, which is not part of the "bounce hops"
    links
    |> Enum.drop(1)
    |> Enum.map(& &1.nip)
  end

  # def resolve_bounce_hops(%VPN{} = vpn) do
  #   # The route passes through a VPN. We need to grab the NIP for each member of the VPN
  # end
end
