defmodule Game.Henforcers.Entity do
  alias Game.Henforcers
  alias Game.Services, as: Svc
  alias Game.Entity

  # TODO: DOC + Specs
  def entity_exists?(%Entity.ID{} = entity_id) do
    case Svc.Entity.fetch(by_id: entity_id) do
      %_{} = entity ->
        {true, %{entity: entity}}

      nil ->
        {false, {:entity, :not_found}, %{}}
    end
  end

  # TODO: DOC + Specs
  def is_player?(%Entity.ID{} = entity_id) do
    with {true, %{entity: entity} = relay} <- entity_exists?(entity_id) do
      case entity.type do
        :player ->
          Henforcers.Player.player_exists?(entity.id)

        _other_type ->
          {false, {:entity, :not_a_player}, relay}
      end
    end
  end
end
