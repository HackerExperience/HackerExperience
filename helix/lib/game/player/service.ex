defmodule Game.Services.Player do
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.Player

  @doc """
  Creates a new player.

  - Creates an Entity linked to the Player.
  - Creates a server for the Entity.
  - Inserts the player in the `universe.players` table.
  - Creates the `player` shard (identified by `player.id`)
  """
  def setup(external_id) when is_binary(external_id) do
    with {:ok, entity} <- Svc.Entity.create(:player),
         {:ok, _} <- Svc.Server.setup(entity),
         {:ok, player} <- insert_player(%{id: entity.id, external_id: external_id}) do
      DB.with_context(fn ->
        player_db_path = DB.Repo.get_path(Core.get_player_context(), player.id)
        false = File.exists?(player_db_path)

        Core.begin_context(:player, player.id, :write)
        DB.commit()
      end)

      {:ok, player}
    end
  end

  defp insert_player(params) do
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

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end
end
