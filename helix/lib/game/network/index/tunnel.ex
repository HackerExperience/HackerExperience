defmodule Game.Index.Tunnel do
  use Norm
  import Core.Spec
  alias Core.{ID, NIP}
  alias Game.Services, as: Svc
  alias Game.{Entity, Server, Tunnel}

  @type index ::
          [map]

  @type rendered_index ::
          [rendered_tunnel]

  @typep rendered_tunnel :: %{
           tunnel_id: ID.external(),
           source_nip: NIP.external(),
           target_nip: NIP.external()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxTunnel",
        tunnel_id: external_id(),
        source_nip: nip(),
        target_nip: nip()
      }),
      [:tunnel_id, :source_nip, :target_nip]
    )
  end

  @doc """
  Returns a list of every tunnel originating in the given NIP.
  """
  @spec index(NIP.t()) ::
          index
  def index(nip) do
    Svc.Tunnel.list(by_source_nip: nip)
  end

  @spec render_index(index, Server.id(), Entity.id()) ::
          rendered_index
  def render_index(index, server_id, entity_id) do
    Enum.map(index, &render_tunnel(&1, server_id, entity_id))
  end

  defp render_tunnel(%Tunnel{} = tunnel, %Server.ID{} = server_id, entity_id) do
    %{
      tunnel_id: tunnel.id |> ID.to_external(entity_id, server_id),
      source_nip: tunnel.source_nip |> NIP.to_external(),
      target_nip: tunnel.target_nip |> NIP.to_external()
    }
  end
end
