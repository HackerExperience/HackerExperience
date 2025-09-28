defmodule Test.Random.Network do
  use Test.Setup.Definition

  alias Core.NIP

  def nip(opts \\ []) do
    network_id = opts[:network_id] || "0"
    ip = opts[:ip] || ip()

    NIP.new(network_id, ip)
  end

  def ip, do: Random.ip()
end
