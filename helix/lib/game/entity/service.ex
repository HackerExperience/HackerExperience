defmodule Game.Services.Entity do
  alias Feeb.DB
  alias Game.Entity

  @doc """
  Creates an Entity.

  This function should be handled by the specialized layer (Player/NPC/Clan).
  """
  def create(entity_type) when entity_type in [:player, :npc, :clan] do
    {is_player, is_npc, is_clan} =
      case entity_type do
        :player -> {true, false, false}
        :npc -> {false, true, false}
        :clan -> {false, false, true}
      end

    %{is_player: is_player, is_npc: is_npc, is_clan: is_clan}
    |> Entity.new()
    |> DB.insert()
  end
end
