defmodule Game.Index.Player do
  use Norm
  import Core.Spec
  alias Core.{ID, NIP}
  alias Game.Services, as: Svc
  alias Game.Index
  alias Game.Player

  @type index ::
          %{
            mainframe_id: ID.external(),
            mainframe_nip: NIP.t(),
            gateways: [Index.Server.gateway_index()],
            endpoints: [Index.Server.endpoint_index()]
          }

  @type rendered_index ::
          %{
            mainframe_id: binary(),
            mainframe_nip: NIP.external(),
            gateways: [Index.Server.rendered_gateway_index()],
            endpoints: [Index.Server.rendered_endpoint_index()]
          }

  def output_spec do
    selection(
      schema(%{
        __openapi_name: "IdxPlayer",
        mainframe_id: external_id(),
        mainframe_nip: nip(),
        gateways: coll_of(Index.Server.gateway_spec()),
        endpoints: coll_of(Index.Server.endpoint_spec())
      }),
      [:mainframe_id, :mainframe_nip, :gateways, :endpoints]
    )
  end

  @spec index(player :: Player.t()) ::
          index
  def index(player) do
    entity = Svc.Entity.fetch!(by_id: player.id)

    gateways = Svc.Server.list(by_entity_id: entity.id)
    mainframe = List.first(gateways)

    mainframe_nip = Svc.NetworkConnection.fetch!(by_server_id: mainframe.id).nip

    %{
      mainframe_id: mainframe.id,
      mainframe_nip: mainframe_nip,
      gateways: Enum.map(gateways, fn server -> Index.Server.gateway_index(entity.id, server) end)
    }
    |> index_add_endpoints(entity)
  end

  defp index_add_endpoints(partial_index, entity) do
    endpoints =
      partial_index.gateways
      |> Enum.flat_map(& &1.tunnels)
      |> Enum.map(fn %{target_nip: endpoint_nip} ->
        endpoint_id = Svc.NetworkConnection.fetch!(by_nip: endpoint_nip).server_id
        Index.Server.endpoint_index(entity.id, endpoint_id, endpoint_nip)
      end)

    Map.put(partial_index, :endpoints, endpoints)
  end

  @spec render_index(index, Player.id()) ::
          rendered_index
  def render_index(index, player_id) do
    entity = Svc.Entity.fetch!(by_id: player_id)

    # NOTE: We switch to the Player context (:read) so that every ExternalID call happens without
    # context switching.
    Core.with_context(:player, player_id, :read, fn ->
      %{
        mainframe_id: index.mainframe_id |> ID.to_external(player_id),
        mainframe_nip: index.mainframe_nip |> NIP.to_external(),
        gateways:
          Enum.map(index.gateways, fn idx -> Index.Server.render_gateway_index(idx, entity.id) end),
        endpoints:
          Enum.map(index.endpoints, fn idx -> Index.Server.render_endpoint_index(idx, entity.id) end)
      }
    end)
  end
end
