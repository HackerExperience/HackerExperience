defmodule Game.Henforcers.Entity do
  alias Game.Henforcers
  alias Game.Services, as: Svc
  alias Game.Entity

  @type entity_exists_relay :: %{entity: term()}
  @type entity_exists_error :: {false, {:entity, :not_found}, %{}}

  @doc """
  Checks whether the given Entity exists
  """
  @spec entity_exists?(Entity.ID.t()) ::
          {true, entity_exists_relay}
          | entity_exists_error
  def entity_exists?(%Entity.ID{} = entity_id) do
    case Svc.Entity.fetch(by_id: entity_id) do
      %_{} = entity ->
        {true, %{entity: entity}}

      nil ->
        {false, {:entity, :not_found}, %{}}
    end
  end

  @type is_player_relay :: Henforcers.Player.player_exists_relay()
  @type is_player_error ::
          {false, {:entity, :not_a_player}, is_player_relay}
          | entity_exists_error

  @doc """
  Checks whether the given Entity is a Player (instead of an NPC, Clan etc).
  """
  @spec is_player?(Entity.ID.t()) ::
          {true, is_player_relay}
          | is_player_error
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
