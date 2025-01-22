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
           id: integer(),
           revision_id: integer(),
           type: String.t()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxLog",
        id: integer(),
        revision_id: integer(),
        type: binary()
      }),
      [:id, :revision_id, :type]
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
    visible_logs =
      Core.with_context(:player, entity_id, :read, fn ->
        Svc.Log.list(visible_on_server: server_id)
      end)

    # Fetch each visible log
    Core.with_context(:server, server_id, :read, fn ->
      Enum.map(visible_logs, fn [log_id, revision_id] ->
        Svc.Log.fetch(by_id_and_revision_id: {log_id, revision_id})
      end)
    end)
  end

  @spec render_index(index) ::
          rendered_index
  def render_index(index) do
    Enum.map(index, &render_log/1)
  end

  defp render_log(%Log{} = log) do
    %{
      id: ID.to_external(log.id),
      revision_id: log.revision_id,
      type: "#{log.type}"
    }
  end
end
