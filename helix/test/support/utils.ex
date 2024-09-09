defmodule Test.Utils do
  alias __MODULE__, as: U

  defdelegate jwt_token(opts \\ []), to: U.Token, as: :generate
end
