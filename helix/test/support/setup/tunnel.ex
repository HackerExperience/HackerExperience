defmodule Test.Setup.Tunnel do
  use Test.Setup.Definition
  alias Game.Tunnel

  @doc """
  Creates a Tunnel and its corresponding TunnelLinks.
  """
  def new(opts \\ []) do
    parsed_links_from_opts = fn %{source_nip: gtw_nip, target_nip: endp_nip, hops: hops} ->
      %{server_id: gtw_id} = Svc.NetworkConnection.fetch!(by_nip: gtw_nip)
      %{server_id: endp_id} = Svc.NetworkConnection.fetch!(by_nip: endp_nip)

      hops_links =
        Enum.map(hops, fn hop_nip ->
          %{server_id: hop_server_id} = Svc.NetworkConnection.fetch!(by_nip: hop_nip)
          [{hop_nip, hop_server_id}]
        end)

      [{gtw_nip, gtw_id}, hops_links, {endp_nip, endp_id}]
      |> List.flatten()
    end

    {:ok, tunnel} =
      opts
      |> params()
      |> extra_params(opts)
      |> parsed_links_from_opts.()
      |> Svc.Tunnel.create()

    %{tunnel: tunnel}
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:tunnel)

  @doc """
  Creates a "lite" Tunnel: it has no Links.
  """
  def new_lite(opts \\ []) do
    tunnel =
      opts
      |> params()
      |> Tunnel.new()
      |> DB.insert!()

    %{tunnel: tunnel}
  end

  def new_lite!(opts \\ []), do: opts |> new_lite() |> Map.fetch!(:tunnel)

  def params(opts \\ []) do
    %{
      source_nip: Kw.get(opts, :source_nip, "0@1.2.3.4"),
      target_nip: Kw.get(opts, :target_nip, "0@4.3.2.1"),
      access: Kw.get(opts, :access, :ssh),
      status: Kw.get(opts, :status, :open)
    }
  end

  defp extra_params(params, opts) do
    params
    |> Map.put(:hops, Kw.get(opts, :hops, []))
  end
end
