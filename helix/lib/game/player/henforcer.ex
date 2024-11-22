defmodule Game.Henforcers.Player do
  alias Game.Services, as: Svc
  alias Game.{Entity, Player}

  @type player_exists_relay :: %{player: term()}
  @type player_exists_error :: {false, {:player, :not_found}, %{}}

  @doc """
  Checks whether the given Player exists
  """
  @spec player_exists?(Player.ID.t() | Entity.ID.t()) ::
          {true, player_exists_relay}
          | player_exists_error
  def player_exists?(%Player.ID{} = player_id) do
    case Svc.Player.fetch(by_id: player_id) do
      %_{} = player ->
        {true, %{player: player}}

      nil ->
        {false, {:player, :not_found}, %{}}
    end
  end

  def player_exists?(%Entity.ID{id: int_id}),
    do: player_exists?(%Player.ID{id: int_id})
end
