defmodule Test.Setup.Player do
  use Test.Setup.Definition
  alias Game.{Entity, Player}
  alias Game.Services, as: Svc

  @doc """
  Creates the Player object, alongside all related data (including Entity, Server etc), as well as
  the Player (and Server) shards.
  """
  def new(opts \\ []) do
    # We are creating global shards, so we need to enforce random autoincrement
    Test.DB.with_random_autoincrement()

    external_id = Kw.get(opts, :external_id, Random.uuid())
    {:ok, player} = Svc.Player.setup(external_id)

    entity = Svc.Entity.fetch!(by_id: player.id)
    [server] = Svc.Server.list(by_entity_id: entity.id)

    %{player: player, entity: entity, server: server}
  end

  @doc """
  Creates the Player object (and the FK requirements, like Entity) but does not create the shards.
  No servers are created either.
  """
  def new_lite(opts \\ []) do
    entity =
      S.Entity.params()
      |> Entity.new()
      |> DB.insert!()

    player =
      [id: entity.id]
      |> Keyword.merge(opts)
      |> params()
      |> Player.new()
      |> DB.insert!()

    %{player: player, entity: entity}
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:player)
  def new_lite!(opts \\ []), do: opts |> new_lite() |> Map.fetch!(:player)

  def params(opts \\ []) do
    %{
      id: Kw.get(opts, :id, Random.int()),
      external_id: Kw.get(opts, :external_id, Random.uuid())
    }
  end
end
