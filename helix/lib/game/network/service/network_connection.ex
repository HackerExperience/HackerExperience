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

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end
end
