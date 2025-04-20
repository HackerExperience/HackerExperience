defmodule Game.Index.Log do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, Log, Server}

  @type index ::
          [map]

  @type rendered_index ::
          [rendered_log]

  @typep rendered_log :: %{
           id: ID.external(),
           revision_id: ID.external(),
           type: String.t(),
           is_deleted: boolean()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxLog",
        id: external_id(),
        revision_id: external_id(),
        type: binary(),
        is_deleted: boolean()
      }),
      [:id, :revision_id, :type, :is_deleted]
    )
  end

  @doc """
  Returns a list of every log `entity_id` can see in `server_id`.

  This list is ordered: newer logs show up first.
  """
  @spec index(Entity.id(), Server.id()) ::
          index
  def index(entity_id, server_id) do
    # Get all logs that `entity_id` can see in `server_id`
    visible_logs = Svc.Log.list_visibility(entity_id, visible_on_server: server_id)

    # Fetch each visible log. Handle the DB context outside to avoid excessive context switching
    Core.with_context(:server, server_id, :read, fn ->
      Enum.map(visible_logs, fn [log_id, revision_id] ->
        Svc.Log.fetch(server_id, by_id_and_revision_id: {log_id, revision_id})
      end)
    end)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_log(&1, entity_id))
  end

  defp render_log(%Log{} = log, entity_id) do
    %{
      id: ID.to_external(log.id, entity_id, log.server_id),
      revision_id: ID.to_external(log.revision_id, entity_id, log.server_id, log.id),
      type: "#{log.type}",
      is_deleted: log.is_deleted
    }
  end
end
