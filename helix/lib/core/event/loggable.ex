defmodule Core.Event.Loggable do
  @behaviour Core.Event.Handler.Behaviour

  require Logger

  alias Game.Services, as: Svc
  alias Game.Log

  @impl true
  def on_event(%ev_mod{}, ev) do
    ev_mod
    |> get_loggable_mod()
    |> apply(:log_map, [ev])
    |> format_map()
    |> generate_entries()
    |> Enum.each(fn {server_id, entity_id, {log_type, log_data}} ->
      log_params = %{type: log_type, data: log_data}

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
         server_id: server_id,
         entity_id: entity_id,
         type: log_type,
         data: raw_data
       }) do
    data_mod = Log.data_mod(log_type)
    [{server_id, entity_id, {log_type, data_mod.new(raw_data)}}]
  end

  # Remote log
  defp generate_entries(%{
         entity_id: entity_id,
         gateway_id: gateway_id,
         endpoint_id: endpoint_id,
         tunnel_id: tunnel_id,
         type_gateway: gtw_log_type,
         data_gateway: gtw_raw_data,
         type_endpoint: endp_log_type,
         data_endpoint: endp_raw_data,
         opts: _opts
       }) do
    tunnel_links = Svc.Tunnel.list_links(on_tunnel: tunnel_id)

    access_point_nip = get_access_point_nip(tunnel_links)
    exit_node_nip = get_exit_node_nip(tunnel_links)

    data_mod_gateway = Log.data_mod(gtw_log_type)

    data_gateway =
      gtw_raw_data
      |> replace_nips(access_point_nip, exit_node_nip)
      |> data_mod_gateway.new()

    data_mod_endpoint = Log.data_mod(endp_log_type)

    data_endpoint =
      endp_raw_data
      |> replace_nips(access_point_nip, exit_node_nip)
      |> data_mod_endpoint.new()

    gateway_entry = {gateway_id, entity_id, {gtw_log_type, data_gateway}}
    endpoint_entry = {endpoint_id, entity_id, {endp_log_type, data_endpoint}}

    # TODO: VPN entries
    [gateway_entry, endpoint_entry]
  end

  defp get_access_point_nip([_gtw, endp]), do: endp.nip
  defp get_access_point_nip(links), do: Enum.at(links, 2).nip

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
