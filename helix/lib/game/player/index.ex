defmodule Game.Index.Player do
  use Norm
  import Core.Spec
  alias Game.Services, as: Svc

  @type index ::
          %{
            mainframe_id: server_id :: integer()
          }

  @type rendered_index ::
          %{
            mainframe_id: integer()
          }

  def output_spec do
    selection(
      schema(%{
        __openapi_name: "IdxPlayer",
        mainframe_id: integer()
      }),
      [:__openapi_name, :mainframe_id]
    )
  end

  @spec index(player :: map()) ::
          index
  def index(player) do
    gateways = Svc.Server.list(by_entity_id: player.id)
    mainframe = List.first(gateways)

    %{
      mainframe_id: mainframe.id
    }
  end

  @spec render_index(index) ::
          rendered_index
  def render_index(index) do
    %{
      mainframe_id: index.mainframe_id
    }
  end
end
