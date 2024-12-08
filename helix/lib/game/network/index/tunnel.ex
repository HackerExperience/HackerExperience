defmodule Game.Index.Tunnel do
  use Norm
  import Core.Spec
  alias Core.{ID, NIP}
  alias Game.Services, as: Svc
  alias Game.Tunnel

  @type index ::
          [map]

  @type rendered_index ::
          [rendered_tunnel]

  @typep rendered_tunnel :: %{
           tunnel_id: integer(),
           source_nip: binary(),
           target_nip: binary()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxTunnel",
        tunnel_id: integer(),
        source_nip: binary(),
        target_nip: binary()
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

  @spec render_index(index()) ::
          rendered_index
  def render_index(index) do
    Enum.map(index, &render_tunnel/1)
  end

  defp render_tunnel(%Tunnel{} = tunnel) do
    %{
      tunnel_id: tunnel.id |> ID.to_external(),
      source_nip: tunnel.source_nip |> NIP.to_external(),
      target_nip: tunnel.target_nip |> NIP.to_external()
    }
  end
end
