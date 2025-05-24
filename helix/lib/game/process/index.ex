defmodule Game.Index.Process do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Process}

  @type index ::
          [map]

  @type rendered_index ::
          [rendered_process]

  @typep rendered_process :: %{
           id: ID.external(),
           type: String.t(),
           data: String.t()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxProcess",
        id: external_id(),
        type: binary(),
        data: binary()
      }),
      [:id, :type, :data]
    )
  end

  @spec index(Entity.id(), Server.id()) ::
          index
  def index(entity_id, server_id) do
    []

    Svc.Process.list(server_id, by_entity: entity_id)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_process(&1, entity_id))
  end

  defp render_process(%Process{} = process, entity_id) do
    IO.inspect(process)
    IO.inspect(process.data)
    IO.inspect(process.data |> Map.from_struct())

    %{
      id: ID.to_external(process.id, entity_id, process.server_id),
      type: "#{process.type}",
      data: "{\"foo\":\"bar\"}"
    }
  end
end
