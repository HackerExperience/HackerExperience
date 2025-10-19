defmodule Game.Index.Server do
  use Norm
  import Core.Spec
  alias Core.{ID, NIP}
  alias Game.Index
  alias Game.Services, as: Svc
  alias Game.{Entity, Server}

  @type gateway_index ::
          %{
            id: Server.id(),
            nip: NIP.t(),
            installations: Index.Installation.index(),
            tunnels: Index.Tunnel.index(),
            files: Index.File.index(),
            logs: Index.Log.index(),
            processes: Index.Process.index(),
            scanner_instances: Index.Scanner.index()
          }

  @type endpoint_index ::
          %{
            nip: NIP.t(),
            files: Index.File.index(),
            logs: Index.Log.index(),
            processes: Index.Process.index(),
            scanner_instances: Index.Scanner.index()
          }

  @type rendered_gateway_index ::
          %{
            id: ID.external(),
            nip: binary(),
            installations: Index.Installation.rendered_index(),
            tunnels: Index.Tunnel.rendered_index(),
            files: Index.File.rendered_index(),
            logs: Index.Log.rendered_index(),
            processes: Index.Process.rendered_index(),
            scanner_instances: Index.Scanner.rendered_index()
          }

  @type rendered_endpoint_index ::
          %{
            nip: NIP.external(),
            files: Index.File.rendered_index(),
            logs: Index.Log.rendered_index(),
            processes: Index.Process.rendered_index(),
            scanner_instances: Index.Scanner.rendered_index()
          }

  def gateway_spec do
    selection(
      schema(%{
        __openapi_name: "IdxGateway",
        id: external_id(),
        nip: nip(),
        installations: coll_of(Index.Installation.spec()),
        tunnels: coll_of(Index.Tunnel.spec()),
        files: coll_of(Index.File.spec()),
        logs: coll_of(Index.Log.spec()),
        processes: coll_of(Index.Process.spec()),
        scanner_instances: coll_of(Index.Scanner.spec())
      }),
      [:id, :nip, :installations, :tunnels, :files, :logs, :processes, :scanner_instances]
    )
  end

  def endpoint_spec do
    selection(
      schema(%{
        __openapi_name: "IdxEndpoint",
        nip: binary(),
        files: coll_of(Index.File.spec()),
        logs: coll_of(Index.Log.spec()),
        processes: coll_of(Index.Process.spec()),
        scanner_instances: coll_of(Index.Scanner.spec())
      }),
      [:nip, :files, :logs, :processes, :scanner_instances]
    )
  end

  @spec gateway_index(Entity.id(), Server.t()) ::
          gateway_index
  def gateway_index(%Entity.ID{} = entity_id, server) do
    %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server.id)

    installations = Index.Installation.index(server.id)

    %{
      id: server.id,
      nip: nip,
      installations: installations,
      tunnels: Index.Tunnel.index(nip),
      files: Index.File.index(entity_id, server.id, installations),
      logs: Index.Log.index(entity_id, server.id),
      processes: Index.Process.index(entity_id, server.id),
      scanner_instances: Index.Scanner.index(entity_id, server.id)
    }
  end

  @spec endpoint_index(Entity.id(), Server.id(), NIP.t()) ::
          endpoint_index
  def endpoint_index(%Entity.ID{} = entity_id, server_id, nip) do
    %{
      nip: nip,
      files: Index.File.index(entity_id, server_id, []),
      logs: Index.Log.index(entity_id, server_id),
      processes: Index.Process.index(entity_id, server_id),
      scanner_instances: Index.Scanner.index(entity_id, server_id)
    }
  end

  @spec render_gateway_index(gateway_index, Entity.id()) ::
          rendered_gateway_index
  def render_gateway_index(index, entity_id) do
    %{
      id: index.id |> ID.to_external(entity_id),
      nip: index.nip |> NIP.to_external(),
      installations: Index.Installation.render_index(index.installations, entity_id),
      tunnels: Index.Tunnel.render_index(index.tunnels, index.id, entity_id),
      files: Index.File.render_index(index.files, entity_id),
      logs: Index.Log.render_index(index.logs, entity_id),
      processes: Index.Process.render_index(index.processes, entity_id),
      scanner_instances: Index.Scanner.render_index(index.scanner_instances, entity_id)
    }
  end

  @spec render_endpoint_index(endpoint_index, Entity.id()) ::
          rendered_endpoint_index
  def render_endpoint_index(index, entity_id) do
    %{
      nip: index.nip |> NIP.to_external(),
      files: Index.File.render_index(index.files, entity_id),
      logs: Index.Log.render_index(index.logs, entity_id),
      processes: Index.Process.render_index(index.processes, entity_id),
      scanner_instances: Index.Scanner.render_index(index.scanner_instances, entity_id)
    }
  end
end
