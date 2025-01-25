defmodule Core.Event.Loggable do
  @behaviour Core.Event.Handler.Behaviour

  require Logger

  alias Game.Services, as: Svc
  alias Game.{Log, Tunnel}

  @impl true
  def on_event(%ev_mod{}, ev) do
    ev_mod
    |> get_loggable_mod()
    |> apply(:log_map, [ev])
    |> format_map()
    |> generate_entries()
    |> Enum.each(fn {server_id, entity_id, {log_type, direction, log_data}} ->
      log_params = %{type: log_type, direction: direction, data: log_data}

      case Svc.Log.create_new(entity_id, server_id, log_params) do
        {:ok, _} ->
          :ok

        error ->
          Logger.error("Failed inserting log: #{inspect(error)}")
      end
    end)
  end

  defp format_map(log_map) do
    log_map
    |> Map.put_new(:opts, %{})
  end

  # Local log
  defp generate_entries(%{
         target_id: server_id,
         entity_id: entity_id,
         type: log_type,
         data: %{gateway: gtw_raw_data},
         tunnel_id: nil,
         opts: _opts
       }) do
    data_mod = Log.data_mod({log_type, :self})
    [{server_id, entity_id, {log_type, :self, data_mod.new(gtw_raw_data)}}]
  end

  # Remote log
  defp generate_entries(%{
         entity_id: entity_id,
         target_id: endpoint_id,
         tunnel_id: %Tunnel.ID{} = tunnel_id,
         type: log_type,
         data: %{gateway: gtw_raw_data, endpoint: endp_raw_data},
         opts: _opts
       }) do
    gtw_raw_data = Map.put(gtw_raw_data, :nip, "$access_point")
    endp_raw_data = Map.put(endp_raw_data, :nip, "$exit_node")

    tunnel_links =
      Core.with_context(:universe, :read, fn ->
        Svc.Tunnel.list_links(on_tunnel: tunnel_id)
      end)

    gateway_id = get_gateway_id(tunnel_links)

    access_point_nip = get_access_point_nip(tunnel_links)
    exit_node_nip = get_exit_node_nip(tunnel_links)

    data_mod_gateway = Log.data_mod({log_type, :to_ap})

    data_gateway =
      gtw_raw_data
      |> replace_nips(access_point_nip, exit_node_nip)
      |> data_mod_gateway.new()

    data_mod_endpoint = Log.data_mod({log_type, :from_en})

    data_endpoint =
      endp_raw_data
      |> replace_nips(access_point_nip, exit_node_nip)
      |> data_mod_endpoint.new()

    gateway_entry = {gateway_id, entity_id, {log_type, :to_ap, data_gateway}}
    endpoint_entry = {endpoint_id, entity_id, {log_type, :from_en, data_endpoint}}
    vpn_entries = build_vpn_entries(tunnel_links, entity_id)

    [gateway_entry, vpn_entries, endpoint_entry]
    |> List.flatten()
  end

  defp build_vpn_entries([_, _], _), do: []

  defp build_vpn_entries(links, entity_id) do
    total_links = length(links)
    log_type = :connection_proxied
    log_data_mod = Log.data_mod({log_type, :hop})

    gen_log = fn from_nip, to_nip ->
      log_data_mod.new(%{from_nip: from_nip, to_nip: to_nip})
    end

    links
    |> Enum.with_index()
    |> Enum.reduce({[], nil}, fn
      {link, _idx}, {[], nil} ->
        # The first link won't create an entry because that's the Gateway
        {[], link}

      {_, idx}, {acc, _} when idx == total_links - 1 ->
        # The last link won't be added either because that's the Endpoint
        acc

      {link, idx}, {acc, prev_link} ->
        next_link = Enum.at(links, idx + 1)

        entry =
          {link.server_id, entity_id, {log_type, :hop, gen_log.(prev_link.nip, next_link.nip)}}

        {[entry | acc], link}
    end)
  end

  defp get_gateway_id([gtw | _]), do: gtw.server_id
  defp get_access_point_nip([_gtw, endp_or_ap | _]), do: endp_or_ap.nip
  defp get_exit_node_nip([gtw, _endp]), do: gtw.nip
  defp get_exit_node_nip(links), do: Enum.at(links, -2).nip

  defp replace_nips(params, ap_nip, en_nip) do
    params
    |> Enum.reduce([], fn {k, v}, acc ->
      new_v =
        case v do
          "$access_point" -> ap_nip
          "$exit_node" -> en_nip
          _ -> v
        end

      [{k, new_v} | acc]
    end)
    |> Enum.into(%{})
  end

  @impl true
  def probe(%_{data: %ev_mod{}}) do
    if function_exported?(get_loggable_mod(ev_mod), :log_map, 1) do
      __MODULE__
    else
      nil
    end
  end

  # We may need to connect to multiple Server shards depending on the event, so for the Loggable
  # trigger in particular the transaction lifecycle is fully handled in the `on_event`/2 callback
  @impl true
  def on_prepare_db(_, _), do: :skip

  @impl true
  def teardown_db_on_success(_, _), do: :skip

  @impl true
  def teardown_db_on_failure(_, _), do: :skip

  def get_loggable_mod(ev_mod), do: Module.concat(ev_mod, Loggable)
end
