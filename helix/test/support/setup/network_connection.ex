defmodule Test.Setup.NetworkConnection do
  use Test.Setup.Definition
  alias Game.NetworkConnection

  def new(server_id, opts \\ []) do
    network_connection =
      [server_id: server_id]
      |> Keyword.merge(opts)
      |> params()
      |> NetworkConnection.new()
      |> DB.insert!()

    %{network_connection: network_connection}
  end

  def new!(server_id, opts \\ []), do: server_id |> new(opts) |> Map.fetch!(:network_connection)

  def params(opts \\ []) do
    %{
      nip: infer_nip_from_opts(opts),
      server_id: Kw.fetch!(opts, :server_id)
    }
  end

  defp infer_nip_from_opts(opts) do
    network_id = opts[:network_id] || 0
    ip = opts[:ip] || "1.2.3.4"
    opts[:nip] || "#{network_id}@#{ip}"
  end
end
