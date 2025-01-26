defmodule Test.Utils do
  alias __MODULE__, as: U

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
  defdelegate start_sse_listener(ctx, player, opts \\ []), to: U.SSEListener, as: :start
  defdelegate wait_sse_event!(event_name), to: U.SSEListener

  # File
  defdelegate get_all_files(server_id), to: U.File

  # Log
  defdelegate get_all_logs(server_id), to: U.Log
  defdelegate get_all_log_visibilities(player_id), to: U.Log
  defdelegate get_all_log_visibilities_on_server(player_id, server_id), to: U.Log

  # Process
  defdelegate get_all_process_registries, to: U.Process
  defdelegate get_all_processes(server_id), to: U.Process
  defdelegate simulate_process_completion(process), to: U.Process
  defdelegate start_top(server_id, opts \\ []), to: U.Process

  # Misc
  defdelegate sleep_on_ci(duration), to: U.CI
end
