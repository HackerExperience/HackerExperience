defmodule Game.Index.Server do
  use Norm
  import Core.Spec
  alias Core.NIP
  alias Game.Index
  alias Game.Services, as: Svc
  alias Game.{Entity, Server}

  @type gateway_index ::
          %{
            id: Server.id(),
            nip: NIP.t(),
            tunnels: Index.Tunnel.index(),
            logs: Index.Log.index(),
            processes: Index.Process.index()
          }

  @type endpoint_index ::
          %{
            nip: NIP.t(),
            logs: Index.Log.index(),
            processes: Index.Process.index()
          }

  @type rendered_gateway_index ::
          %{
            nip: binary(),
            tunnels: Index.Tunnel.rendered_index(),
            logs: Index.Log.rendered_index(),
            processes: Index.Process.rendered_index()
          }

  @type rendered_endpoint_index ::
          %{
            nip: NIP.external(),
            logs: Index.Log.rendered_index(),
            processes: Index.Process.rendered_index()
          }

  def gateway_spec do
    selection(
      schema(%{
        __openapi_name: "IdxGateway",
        nip: nip(),
        tunnels: coll_of(Index.Tunnel.spec()),
        logs: coll_of(Index.Log.spec()),
        processes: coll_of(Index.Process.spec())
      }),
      [:nip, :tunnels, :logs, :processes]
    )
  end

  def endpoint_spec do
    selection(
      schema(%{
        __openapi_name: "IdxEndpoint",
        nip: binary(),
        processes: coll_of(Index.Process.spec()),
        logs: coll_of(Index.Log.spec())
      }),
      [:nip, :logs, :processes]
    )
  end

  @spec gateway_index(Entity.t(), Server.t()) ::
          gateway_index
  def gateway_index(entity, server) do
    %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server.id)

    %{
      id: server.id,
      nip: nip,
      logs: Index.Log.index(entity.id, server.id),
      processes: Index.Process.index(entity.id, server.id),
      tunnels: Index.Tunnel.index(nip)
    }
  end

  @spec endpoint_index(Entity.id(), Server.id(), NIP.t()) ::
          endpoint_index
  def endpoint_index(%Entity.ID{} = entity_id, server_id, nip) do
    %{
      nip: nip,
      logs: Index.Log.index(entity_id, server_id),
      processes: Index.Process.index(entity_id, server_id)
    }
  end

  @spec render_gateway_index(gateway_index, Entity.id()) ::
          rendered_gateway_index
  def render_gateway_index(index, entity_id) do
    %{
      nip: index.nip |> NIP.to_external(),
      logs: Index.Log.render_index(index.logs, entity_id),
      processes: Index.Process.render_index(index.processes, entity_id),
      tunnels: Index.Tunnel.render_index(index.tunnels, index.id, entity_id)
    }
  end

  @spec render_endpoint_index(endpoint_index, Entity.id()) ::
          rendered_endpoint_index
  def render_endpoint_index(index, _entity_id) do
    %{
      nip: index.nip |> NIP.to_external(),
      # TODO
      logs: [],
      # TODO
      processes: []
    }
  end
end
