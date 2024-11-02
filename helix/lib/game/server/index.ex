defmodule Game.Index.Server do
  use Norm
  import Core.Spec
  alias Game.Index

  def gateway_spec do
    selection(
      schema(%{
        __openapi_name: "IdxGateway",
        id: integer(),
        logs: coll_of(Index.Log.spec())
      }),
      [:id, :logs]
    )
  end

  def gateway_index(player, server) do
    %{
      id: server.id,
      logs: Index.Log.index(player.id, server.id)
    }
  end

  def render_gateway_index(gateway_index) do
    gateway_index
  end
end
