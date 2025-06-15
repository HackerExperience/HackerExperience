defmodule Game.Index.Process do
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, Process, Server}

  @type index ::
          [map]

  @type rendered_index ::
          [rendered_process]

  @typep rendered_process :: %{
           id: ID.external(),
           type: String.t(),
           data: String.t()
         }

  def spec,
    do: Process.Viewable.spec()

  @spec index(Entity.id(), Server.id()) ::
          index
  def index(entity_id, server_id) do
    Svc.Process.list(server_id, by_entity: entity_id)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_process(&1, entity_id))
  end

  defp render_process(%Process{} = process, entity_id) do
    Process.Viewable.render(process, entity_id)
  end
end
