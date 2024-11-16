defmodule Game.Services.NetworkConnection do
  @doc """
  TODO DOCME
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_nip: {:one, {:network_connections, :by_nip}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end
end
