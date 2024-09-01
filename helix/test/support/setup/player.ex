defmodule Test.Setup.Player do
  use Test.Setup
  alias Game.Player

  def new(opts \\ []) do
    entity = S.Entity.new!()

    # TODO: This is not creating the player shard, so it isn't 100% correct

    player =
      [id: entity.id]
      |> Keyword.merge(opts)
      |> params()
      |> Player.new()
      |> DB.insert!()

    {player, %{entity: entity}}
  end

  def new!(opts \\ []), do: opts |> new() |> elem(0)

  def params(opts \\ []) do
    %{
      id: Kw.get(opts, :id, Random.int()),
      external_id: Kw.get(opts, :external_id, Random.uuid())
    }
  end
end
