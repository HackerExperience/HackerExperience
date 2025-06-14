defmodule Game.Index.Log do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, Log, Server}

  @type index ::
          [{raw_log_id :: integer(), [index_log_entry]}]

  @typep index_log_entry ::
           {map, personal_revision_id :: integer()}

  @type rendered_index ::
          [rendered_log]

  @typep rendered_log :: %{
           id: ID.external(),
           revisions: [rendered_revision],
           revision_count: integer(),
           is_deleted: boolean()
         }

  @typep rendered_revision :: %{
           revision_id: integer(),
           type: String.t(),
           direction: String.t(),
           data: String.t(),
           source: String.t()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxLog",
        id: external_id(),
        revisions: coll_of(revision_spec()),
        revision_count: integer(),
        is_deleted: boolean()
      }),
      [:id, :revisions, :revision_count, :is_deleted]
    )
  end

  defp revision_spec do
    selection(
      schema(%{
        __openapi_name: "IdxLogRevision",
        revision_id: integer(),
        type: binary(),
        direction: binary(),
        data: binary(),
        source: binary()
      }),
      [:revision_id, :type, :direction, :data, :source]
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

    # Group visible logs based on their revisions
    visible_logs =
      Enum.reduce(visible_logs, {%{}, 1, nil}, fn [log_id, real_revision_id, source],
                                                  {acc, personal_revision_counter, prev_log_id} ->
        # Increment the rev counter if this log is the same as the previous one; reset otherwise
        personal_revision_counter = (log_id == prev_log_id && personal_revision_counter + 1) || 1

        entry = {log_id, personal_revision_counter, real_revision_id, source}
        new_acc = Map.put(acc, log_id, [entry | Map.get(acc, log_id, [])])
        {new_acc, personal_revision_counter, log_id}
      end)
      |> elem(0)
      |> Enum.reverse()

    # Fetch each visible log. Handle the DB context outside to avoid excessive context switching
    Core.with_context(:server, server_id, :read, fn ->
      Enum.map(visible_logs, fn {log_group_id, revisions_ids} ->
        revisions =
          Enum.map(revisions_ids, fn {log_id, personal_revision_id, revision_id, source} ->
            log = Svc.Log.fetch(server_id, by_id_and_revision_id: {log_id, revision_id})
            {log, personal_revision_id, source}
          end)

        {log_group_id, revisions}
      end)
    end)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_log(&1, entity_id))
  end

  defp render_log({_, revisions}, entity_id) do
    # For the purposes of "parent" log, it doesn't matter which log we pick
    {parent_log, _, _} = List.first(revisions)

    %{
      id: ID.to_external(parent_log.id, entity_id, parent_log.server_id),
      revisions: Enum.map(revisions, &render_revision/1),
      revision_count: length(revisions),
      is_deleted: parent_log.is_deleted
    }
  end

  defp render_revision({%Log{} = log, personal_revision_id, visibility_source}) do
    data_mod = Log.data_mod({log.type, log.direction})

    %{
      revision_id: personal_revision_id,
      type: "#{log.type}",
      direction: "#{log.direction}",
      data: data_mod.render(log.data) |> :json.encode() |> to_string(),
      source: "#{visibility_source}"
    }
  end
end
