defmodule Game.Services.Player do
  alias DBLite, as: DB
  alias Game.Player

  # Operations

  def create(params) do
    params
    |> Player.new()
    |> DB.insert()
  end

  # Queries

  @doc """
  Fetches a Player.

  Filters:
  - by_id
  - by_external_id
  """
  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:players, :fetch}},
      by_external_id: {:one, {:players, :get_by_external_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end
end
