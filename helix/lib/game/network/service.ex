defmodule Game.Services.Network do
  alias Game.{Tunnel}

  def resolve_bounce_hops(%Tunnel{} = tunnel) do
    # Get all intermediary hops in a tunnel

    # TODO: Splittar o service para Network, NetworkConnection, Tunnel
    raise "Parei aqui"
  end

  # def resolve_bounce_hops(%VPN{} = vpn) do
  #   # The route passes through a VPN. We need to grab the NIP for each member of the VPN
  # end
end
