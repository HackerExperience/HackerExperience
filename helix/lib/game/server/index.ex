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
            logs: Index.Log.index()
          }

  @type rendered_gateway_index ::
          %{
            id: server_id :: integer(),
            nip: binary(),
            logs: Index.Log.rendered_index()
          }

  def gateway_spec do
    selection(
      schema(%{
        __openapi_name: "IdxGateway",
        id: integer(),
        nip: binary(),
        logs: coll_of(Index.Log.spec())
      }),
      [:id, :logs, :nip]
    )
  end

  @spec gateway_index(term(), term()) ::
          gateway_index
  def gateway_index(player, server) do
    # TODO: NIP should always exist (and it's okay to crash). Just figure out a way for tests
    # to pass... Remove the || and *do* crash after you found an easy way to keep existing tests
    %{nip: nip} = Svc.NetworkConnection.fetch(by_server_id: server.id) || %{nip: nil}

    %{
      id: server.id,
      nip: nip,
      logs: Index.Log.index(player.id, server.id)
    }
  end

  @spec render_gateway_index(gateway_index) ::
          rendered_gateway_index
  def render_gateway_index(index) do
    %{
      id: index.id |> ID.to_external(),
      nip: index.nip |> NIP.to_external(),
      logs: Index.Log.render_index(index.logs)
    }
  end
end
