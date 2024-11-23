defmodule Game.Services.Tunnel do
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.{Tunnel, TunnelLink}

  @typep parsed_links :: [parsed_link]
  @typep parsed_link :: {nip :: String.t(), server_id :: integer()}

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:tunnels, :fetch}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def list_links(filter_params, opts \\ []) do
    filters = [
      on_tunnel: {:all, {:tunnel_links, :by_tunnel_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  @doc """
  TODO DOCME
  """
  @spec create(parsed_links) ::
          term
  def create(parsed_links) do
    %{
      nips: nips,
      source_nip: source_nip,
      target_nip: target_nip,
      valid?: links_valid?
    } = get_data_from_parsed_links(parsed_links)

    # TODO: Better error handling
    true = links_valid?

    access = :ssh

    with {:ok, tunnel} <- do_create(source_nip, target_nip, access),
         {:ok, links} <- do_create_links(tunnel, nips),
         {:ok, _connections} <- Svc.Connection.create(tunnel.id, links, :ssh) do
      {:ok, tunnel}
    else
      e ->
        IO.inspect(e)
        raise "Error!"
    end
  end

  defp do_create(source_nip, target_nip, access) do
    %{
      source_nip: source_nip,
      target_nip: target_nip,
      access: access,
      status: :open
    }
    |> Tunnel.new()
    |> DB.insert()
  end

  defp do_create_links(%Tunnel{} = tunnel, nips) do
    Enum.reduce_while(nips, {:ok, [], 0}, fn nip, {:ok, acc_links, acc_idx} ->
      %{tunnel_id: tunnel.id, idx: acc_idx, nip: nip}
      |> TunnelLink.new()
      |> DB.insert()
      |> case do
        {:ok, link} ->
          {:cont, {:ok, [link | acc_links], acc_idx + 1}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, reversed_links, _} ->
        {:ok, Enum.reverse(reversed_links)}

      {:error, _} = e ->
        e
    end
  end

  defp get_data_from_parsed_links(parsed_links) do
    total_links = length(parsed_links)

    initial_acc =
      %{
        loops: [],
        servers: [],
        nips: [],
        size: total_links,
        source_nip: nil,
        target_nip: nil,
        valid?: true,
        idx: 0
      }

    parsed_links
    |> Enum.reduce(initial_acc, fn {nip, server_id}, acc ->
      acc =
        cond do
          acc.idx == 0 ->
            Map.put(acc, :source_nip, nip)

          acc.idx == total_links - 1 ->
            Map.put(acc, :target_nip, nip)

          true ->
            acc
        end

      acc
      |> Map.update!(:idx, &(&1 + 1))
      |> Map.update!(:servers, fn servers -> [server_id | servers] end)
      |> Map.update!(:nips, fn nips -> [nip | nips] end)
      |> parsed_links_check_for_loops()
    end)
    |> Map.update!(:servers, &Enum.reverse/1)
    |> Map.update!(:nips, &Enum.reverse/1)
  end

  # This is TODO; I need to make sure there are no cyclic graphs in a tunnel
  defp parsed_links_check_for_loops(acc), do: acc
end
