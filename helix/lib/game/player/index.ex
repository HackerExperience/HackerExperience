defmodule Game.Index.Player do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Index

  @type index ::
          %{
            mainframe_id: server_id :: integer(),
            gateways: [Index.Server.gateway_index()]
          }

  @type rendered_index ::
          %{
            mainframe_id: integer(),
            gateways: [Index.Server.rendered_gateway_index()]
          }

  def output_spec do
    selection(
      schema(%{
        __openapi_name: "IdxPlayer",
        mainframe_id: integer(),
        gateways: coll_of(Index.Server.gateway_spec())
      }),
      [:mainframe_id, :gateways]
    )
  end

  @spec index(player :: map()) ::
          index
  def index(player) do
    gateways = Svc.Server.list(by_entity_id: player.id)
    mainframe = List.first(gateways)

    %{
      mainframe_id: mainframe.id,
      gateways: Enum.map(gateways, fn server -> Index.Server.gateway_index(player, server) end)
    }
  end

  @spec render_index(index) ::
          rendered_index
  def render_index(index) do
    %{
      mainframe_id: index.mainframe_id |> ID.to_external(),
      gateways: Enum.map(index.gateways, fn idx -> Index.Server.render_gateway_index(idx) end)
    }
  end
end
