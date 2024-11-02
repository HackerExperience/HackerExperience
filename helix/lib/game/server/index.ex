defmodule Game.Index.Server do
  use Norm
  import Core.Spec
  alias Game.Index

  @type gateway_index ::
          %{
            id: server_id :: integer(),
            logs: Index.Log.index()
          }

  @type rendered_gateway_index ::
          %{
            id: server_id :: integer(),
            logs: Index.Log.rendered_index()
          }

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

  @spec gateway_index(term(), term()) ::
          gateway_index
  def gateway_index(player, server) do
    %{
      id: server.id,
      logs: Index.Log.index(player.id, server.id)
    }
  end

  @spec render_gateway_index(gateway_index) ::
          rendered_gateway_index
  def render_gateway_index(index) do
    %{
      id: index.id,
      logs: Index.Log.render_index(index.logs)
    }
  end
end
