defmodule Test.Random do
  alias Test.Random, as: R

  # IDs
  defdelegate entity_id, to: R.ID
  defdelegate scanner_instance_id, to: R.ID
  defdelegate server_id, to: R.ID
  defdelegate tunnel_id, to: R.ID

  # Network
  defdelegate ip, to: R.Network
  defdelegate nip(opts \\ []), to: R.Network
end
