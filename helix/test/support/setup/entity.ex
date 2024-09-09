defmodule Test.Setup.Entity do
  use Test.Setup.Definition

  @doc """
  Creates a full Entity object, alongside all related data (including shards). Ultimately, the
  actual creation logic is delegated to the specialization of the entity. For example, when
  creating a Player Entity, we will simply call Setup.player/1.
  """
  def new(opts \\ []) do
    case params(opts).type do
      :player ->
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

    %{
      type: Kw.get(opts, :type, :player)
    }
  end
end
