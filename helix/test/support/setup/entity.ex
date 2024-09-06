defmodule Test.Setup.Entity do
  use Test.Setup

  @doc """
  Creates a full Entity object, alongside all related data (including shards). Ultimately, the
  actual creation logic is delegated to the specialization of the entity. For example, when
  creating a Player Entity, we will simply call Setup.player/1.
  """
  def new(opts \\ []) do
    true = opts[:type] in [nil, :player, :npc, :clan]

    cond do
      opts[:type] in [nil, :player] ->
        S.player()
    end
  end

  @doc """
  Creates the Entity object (and FK requirement depending on specialization), like Player OR Clan.
  """
  def new_lite(opts \\ []) do
    true = opts[:type] in [nil, :player, :npc, :clan]

    cond do
      opts[:type] in [nil, :player] ->
        S.player_lite()
    end
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:entity)
  def new_lite!(opts \\ []), do: opts |> new_lite() |> Map.fetch!(:entity)

  def params(opts \\ []) do
    true = opts[:type] in [nil, :player, :npc, :clan]

    # TODO: Refactor entity to have an `entity_type` entry (enum of [:player, :npc, :clan])
    # instead of these 3 boolean columns
    %{
      is_player: Kw.get(opts, :type, :player) == :player,
      is_npc: Kw.get(opts, :type, :player) == :npc,
      is_clan: Kw.get(opts, :type, :player) == :clan
    }
  end
end
