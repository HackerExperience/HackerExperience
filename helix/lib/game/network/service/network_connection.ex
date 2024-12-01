defmodule Game.Services.NetworkConnection do
  @doc """
  TODO DOCME
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_nip: {:one, {:network_connections, :by_nip}},
      by_server_id: {:one, {:network_connections, :by_server_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end
end
