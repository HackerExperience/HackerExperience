defmodule Test.Utils do
  alias __MODULE__, as: U

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
  defdelegate start_sse_listener(ctx, player, opts \\ []), to: U.SSEListener, as: :start
  defdelegate wait_sse_event!(event_name), to: U.SSEListener

  # Core.ID
  defdelegate to_eid(object_id, entity_id, dom_id \\ nil, sub_id \\ nil), to: U.ID, as: :to_eid
  defdelegate from_eid(external_id, entity_id), to: U.ID, as: :from_external_id
  defdelegate from_external_id(external_id, entity_id), to: U.ID

  # File
  defdelegate get_all_files(server_id), to: U.File
  defdelegate get_all_file_visibilities(player_id), to: U.File

  # Log
  defdelegate get_all_logs(server_id), to: U.Log
  defdelegate get_all_log_visibilities(player_id), to: U.Log
  defdelegate get_all_log_visibilities_on_server(player_id, server_id), to: U.Log

  # Network
  defdelegate get_all_tunnels, to: U.Network
  defdelegate get_all_tunnel_links, to: U.Network
  defdelegate get_all_tunnel_links(tunnel_or_id), to: U.Network
  defdelegate get_all_connections, to: U.Network
  defdelegate get_all_connections(tunnel_or_id_or_group_or_id), to: U.Network
  defdelegate get_all_connections(tunnel_or_id_or_group_or_id, conn_type), to: U.Network
  defdelegate get_all_connection_groups, to: U.Network
  defdelegate get_all_connection_groups(tunnel_or_id), to: U.Network

  # Process
  defdelegate get_all_process_registries, to: U.Process
  defdelegate get_all_processes(server_id), to: U.Process
  defdelegate processable_on_complete(process), to: U.Process
  defdelegate simulate_process_completion(process), to: U.Process
  defdelegate start_top(server_id, opts \\ []), to: U.Process

  # Scanner
  defdelegate get_all_scanner_instances, to: U.Scanner
  defdelegate get_all_scanner_tasks, to: U.Scanner
  defdelegate get_task_for_scanner_instance(instance_or_id), to: U.Scanner

  # Misc
  defdelegate sleep_on_ci(duration), to: U.CI
end
