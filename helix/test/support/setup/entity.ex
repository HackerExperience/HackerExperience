defmodule Test.Setup.Entity do
  use Test.Setup
  alias Game.Entity

  def new(opts \\ []) do
    entity =
      opts
      |> params()
      |> Entity.new()
      |> DB.insert!()

    {entity, %{}}
  end

  def new!(opts \\ []), do: opts |> new() |> elem(0)

  def params(opts \\ []) do
    true = opts[:type] in [nil, :player, :npc, :clan]

    %{
      is_player: Kw.get(opts, :type, :player) == :player,
      is_npc: Kw.get(opts, :type, :player) == :npc,
      is_clan: Kw.get(opts, :type, :player) == :clan
    }
  end
end
