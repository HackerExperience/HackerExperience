defmodule Test.Utils do
  alias __MODULE__, as: U

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
  defdelegate start_sse_listener(ctx, player, opts \\ []), to: U.SSEListener, as: :start
end
