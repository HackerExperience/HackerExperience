defmodule Game.Henforcers.Log do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.{Entity, Log, LogVisibility, Server}

  @type log_exists_relay :: %{log: Log.t()}
  @type log_exists_error :: {false, {:log, :not_found}, %{}}

  @doc """
  Checks whether the given Log exists.
  """
  @spec log_exists?(Log.ID.t(), nil, Server.t()) ::
          {true, log_exists_relay}
          | log_exists_error
  def log_exists?(%Log.ID{} = log_id, nil, %Server{} = server) do
    # If `revision_id` is nil, just make sure the log itself exists and return the latest rev
    case Svc.Log.fetch(server.id, by_id: log_id) do
      %Log{} = log ->
        Henforcer.success(%{log: log})

      nil ->
        Henforcer.fail({:log, :not_found})
    end
  end

  @type is_visible_relay :: %{log_visibility: LogVisibility.t()}
  @type is_visible_error :: {false, {:log_visibility, :not_found}, %{}}

  @doc """
  Henforces that the given Entity has Visibility into the given `log`.
  """
  @spec is_visible?(Log.t(), Entity.t()) ::
          {true, is_visible_relay}
          | is_visible_error
  def is_visible?(%Log{} = log, %Entity{id: entity_id}) do
    case Svc.Log.fetch_visibility(entity_id, by_log: log) do
      %LogVisibility{} = visibility ->
        Henforcer.success(%{log_visibility: visibility})

      nil ->
        Henforcer.fail({:log_visibility, :not_found})
    end
  end

  @type not_deleted_relay :: %{}
  @type not_deleted_error :: {false, {:log, :deleted}, %{}}

  @doc """
  Henforces that the Log is *not* deleted.
  """
  @spec not_deleted?(Log.t()) ::
          {true, not_deleted_relay}
          | not_deleted_error
  def not_deleted?(%Log{is_deleted: false}), do: Henforcer.success()
  def not_deleted?(%Log{is_deleted: true}), do: Henforcer.fail({:log, :deleted})

  @type can_edit_relay :: %{log: Log.t(), log_visibility: LogVisibility.t()}
  @type can_edit_error ::
          log_exists_error
          | is_visible_error
          | not_deleted_error

  @doc """
  Aggregator henforcing that the given Entity can edit the given Log in the given Server.
  """
  @spec can_edit?(Server.t(), Entity.t(), Log.id()) ::
          {true, can_edit_relay}
          | can_edit_error
          | not_deleted_error
  def can_edit?(%Server{} = server, %Entity{} = entity, %Log.ID{} = log_id) do
    with {true, %{log: log}} <- log_exists?(log_id, nil, server),
         {true, %{log_visibility: visibility}} <- is_visible?(log, entity),
         {true, _} <- not_deleted?(log) do
      Henforcer.success(%{log: log, log_visibility: visibility})
    end
  end

  @type can_delete_relay :: %{log: Log.t(), log_visibility: LogVisibility.t()}
  @type can_delete_error ::
          log_exists_error
          | is_visible_error
          | not_deleted_error

  @doc """
  Aggregator henforcing that the given Entity can delete the given Log in the given Server.
  """
  @spec can_delete?(Server.t(), Entity.t(), Log.id()) ::
          {true, can_delete_relay}
          | can_delete_error
  def can_delete?(%Server{} = server, %Entity{} = entity, %Log.ID{} = log_id) do
    # At least for now, edit and delete share the same set of permissions
    can_edit?(server, entity, log_id)
  end
end
