defmodule Game.Index.Server do
  use Norm
  import Core.Spec
  alias Core.{ID, NIP}
  alias Game.Index
  alias Game.Services, as: Svc

  @type gateway_index ::
          %{
            id: server_id :: integer(),
            nip: NIP.t(),
            logs: Index.Log.index(),
            tunnels: Index.Tunnel.index()
          }

  @type endpoint_index ::
          %{
            nip: NIP.t(),
            logs: Index.Log.index()
          }

  @type rendered_gateway_index ::
          %{
            id: server_id :: integer(),
            nip: binary(),
            logs: Index.Log.rendered_index(),
            tunnels: Index.Tunnel.rendered_index()
          }

  @type rendered_endpoint_index ::
          %{
            nip: binary(),
            logs: Index.Log.rendered_index()
          }

  def gateway_spec do
    selection(
      schema(%{
        __openapi_name: "IdxGateway",
        id: integer(),
        nip: binary(),
        logs: coll_of(Index.Log.spec()),
        tunnels: coll_of(Index.Tunnel.spec())
      }),
      [:id, :logs, :nip, :tunnels]
    )
  end

  def endpoint_spec do
    selection(
      schema(%{
        __openapi_name: "IdxEndpoint",
        nip: binary(),
        logs: coll_of(Index.Log.spec())
      }),
      [:logs, :nip]
    )
  end

  @spec gateway_index(term(), term()) ::
          gateway_index
  def gateway_index(player, server) do
    %{nip: nip} = Svc.NetworkConnection.fetch!(by_server_id: server.id)

    %{
      id: server.id,
      nip: nip,
      logs: Index.Log.index(player.id, server.id),
      tunnels: Index.Tunnel.index(nip)
    }
  end

  @spec endpoint_index(term(), term(), term()) ::
          endpoint_index
  def endpoint_index(player_id, server_id, nip) do
    %{
      nip: nip,
      logs: Index.Log.index(player_id, server_id)
    }
  end

  @spec render_gateway_index(gateway_index) ::
          rendered_gateway_index
  def render_gateway_index(index) do
    %{
      id: index.id |> ID.to_external(),
      nip: index.nip |> NIP.to_external(),
      logs: Index.Log.render_index(index.logs),
      tunnels: Index.Tunnel.render_index(index.tunnels)
    }
  end

  @spec render_endpoint_index(endpoint_index) ::
          rendered_endpoint_index
  def render_endpoint_index(index) do
    %{
      nip: index.nip |> NIP.to_external(),
      logs: []
    }
  end
end
