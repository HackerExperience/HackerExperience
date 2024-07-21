defmodule Renatils.Random do
  alias __MODULE__

  defdelegate int(opts \\ []), to: Random.Int
  defdelegate uuid(opts \\ []), to: Random.UUID
end
