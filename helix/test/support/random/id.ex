defmodule Test.Random.ID do
  use Test.Setup.Definition

  def entity_id, do: Game.Entity.ID.new(Random.int())
  def server_id, do: Game.Server.ID.new(Random.int())
  def tunnel_id, do: Game.Tunnel.ID.new(Random.int())
end
