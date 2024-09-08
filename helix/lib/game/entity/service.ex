defmodule Game.Services.Entity do
  alias Feeb.DB
  alias Game.Entity

  @doc """
  Creates an Entity.

  This function should be handled by the specialized layer (Player/NPC/Clan).
  """
  def create(entity_type) when entity_type in [:player, :npc, :clan] do
    %{type: entity_type}
    |> Entity.new()
    |> DB.insert()
  end

  # Queries

  @doc """
  Fetches an Entity.

  Filters:
  - by_id
  """
  def fetch(filter_params, opts \\ []) when is_list(filter_params) do
    filters =
      [
        by_id: {:one, {:entities, :fetch}}
      ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end
end
