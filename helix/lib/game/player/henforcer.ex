defmodule Game.Henforcers.Player do
  alias Game.Services, as: Svc
  alias Game.{Entity, Player}

  # TODO: DOC + Specs
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
