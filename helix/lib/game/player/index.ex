defmodule Game.Index.Player do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.Index

  @type index ::
          %{
            mainframe_id: server_id :: integer(),
            gateways: [Index.Server.gateway_index()],
            endpoints: [Index.Server.endpoint_index()]
          }

  @type rendered_index ::
          %{
            mainframe_id: integer(),
            gateways: [Index.Server.rendered_gateway_index()],
            endpoints: [Index.Server.rendered_endpoint_index()]
          }

  def output_spec do
    selection(
      schema(%{
        __openapi_name: "IdxPlayer",
        mainframe_id: integer(),
        gateways: coll_of(Index.Server.gateway_spec()),
        endpoints: coll_of(Index.Server.endpoint_spec())
      }),
      [:mainframe_id, :gateways, :endpoints]
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
    |> index_add_endpoints(player)
  end

  defp index_add_endpoints(partial_index, player) do
    endpoints =
      partial_index.gateways
      |> Enum.flat_map(& &1.tunnels)
      |> Enum.map(fn %{target_nip: endpoint_nip} ->
        endpoint_id = Svc.NetworkConnection.fetch!(by_nip: endpoint_nip).server_id
        Index.Server.endpoint_index(player, endpoint_id, endpoint_nip)
      end)

    Map.put(partial_index, :endpoints, endpoints)
  end

  @spec render_index(index) ::
          rendered_index
  def render_index(index) do
    %{
      mainframe_id: index.mainframe_id |> ID.to_external(),
      gateways: Enum.map(index.gateways, fn idx -> Index.Server.render_gateway_index(idx) end),
      endpoints: Enum.map(index.endpoints, fn idx -> Index.Server.render_endpoint_index(idx) end)
    }
  end
end
