defmodule Test.Utils do
  alias __MODULE__, as: U

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
  defdelegate start_sse_listener(ctx, player, opts \\ []), to: U.SSEListener, as: :start
  defdelegate wait_sse_event!(event_name), to: U.SSEListener, as: :wait_sse_event!

  # Processes
  defdelegate get_all_process_registries, to: U.Process, as: :get_all_process_registries
  defdelegate get_all_processes(server_id), to: U.Process, as: :get_all_processes
end
