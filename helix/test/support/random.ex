defmodule Test.Random do
  alias Test.Random, as: R

  # Network
  defdelegate ip, to: R.Network
  defdelegate nip(opts \\ []), to: R.Network
end
