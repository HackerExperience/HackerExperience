defmodule Game.Services.Log do
  require Logger
  alias Feeb.DB
  alias Game.{Entity, Log, LogVisibility, Server}

  @doc """
  """
  @spec fetch(Server.id(), list, list) ::
          Log.t() | nil
  def fetch(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_id_and_revision_id: &query_by_id_and_revision_id/1,
      by_id: {:one, {:logs, :fetch_latest_by_id}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @spec fetch!(Server.id(), list, list) ::
          Log.t() | no_return
  def fetch!(%Server.ID{} = server_id, filter_params, opts \\ []) do
    server_id
    |> fetch(filter_params, opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end

  @spec list(Server.id(), list, list) ::
          [Log.t()]
  def list(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_scanneable: {:all, {:logs, :get_scanneable_logs}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns the LogVisibility for a particular Log.
  """
  @spec fetch_visibility(Entity.id(), list, list) ::
          LogVisibility.t() | nil
  def fetch_visibility(%Entity.ID{} = entity_id, filter_params, opts \\ []) do
    filters = [
      by_log: &query_visibility_by_log/1
    ]

    Core.with_context(:player, entity_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  @doc """
  Returns a list of LogVisibility matching the given filters.
  """
  @spec list_visibility(Entity.id(), list, list) ::
          [LogVisibility.t()]
  def list_visibility(%Entity.ID{} = entity_id, filter_params, opts \\ []) do
    filters = [
      by_server: {:all, {:log_visibilities, :by_server}},
      visible_on_server: {:all, {:log_visibilities, :by_server_ordered}, format: :raw}
    ]

    Core.with_context(:player, entity_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  def create_new(entity_id, server_id, log_params) do
    Core.with_context(:server, server_id, :write, fn ->
      [last_inserted_id] = DB.one({:logs, :get_last_inserted_id}, [], format: :raw)

      params =
        log_params
        |> Map.put(:id, (last_inserted_id || 0) + 1)
        |> Map.put(:revision_id, 1)

      with {:ok, log} <- insert_log(server_id, params),
           {:ok, _log_visibility} <- insert_visibility(entity_id, server_id, log, :self) do
        {:ok, log}
      else
        error ->
          Logger.error("Unable to create new log: #{inspect(error)}")
          error
      end
    end)
  end

  def create_revision(entity_id, server_id, parent_log_id, log_params) do
    Core.with_context(:server, server_id, :write, fn ->
      [last_revision_id] = DB.one({:logs, :get_log_last_revision_id}, [parent_log_id], format: :raw)

      params =
        log_params
        |> Map.put(:id, parent_log_id)
        |> Map.put(:revision_id, last_revision_id + 1)

      with {:ok, log} <- insert_log(server_id, params),
           {:ok, _log_visibility} <- insert_visibility(entity_id, server_id, log, :edit) do
        {:ok, log}
      else
        error ->
          Logger.error("Unable to create log revision: #{inspect(error)}")
          error
      end
    end)
  end

  def find_log(%Log{} = log, %Entity.ID{} = entity_id, %Server.ID{} = server_id) do
    case insert_visibility(entity_id, server_id, log, :scanner) do
      {:ok, visibility} ->
        {:ok, visibility}

      {:error, reason, _} ->
        {:error, reason}
    end
  end

  def delete(%Log{is_deleted: false} = log, %Entity.ID{} = entity_id) do
    Core.with_context(:server, log.server_id, :write, fn ->
      DB.update_all!({:logs, :soft_delete_all_revisions}, [DateTime.utc_now(), entity_id, log.id])
      :ok
    end)
  end

  defp insert_log(server_id, params) do
    Core.with_context(:server, server_id, :write, fn ->
      params
      |> Log.new()
      |> DB.insert()
      |> on_error_add_step(:log)
    end)
  end

  defp insert_visibility(entity_id, server_id, %Log{} = log, source) do
    Core.with_context(:player, entity_id, :write, fn ->
      %{
        server_id: server_id,
        log_id: log.id,
        revision_id: log.revision_id,
        source: source
      }
      |> LogVisibility.new()
      |> DB.insert()
      |> on_error_add_step(:log_visibility)
    end)
  end

  defp query_by_id_and_revision_id({log_id, revision_id}) do
    DB.one({:logs, :fetch_by_id_and_revision_id}, [log_id, revision_id])
  end

  defp query_visibility_by_log(%Log{} = log) do
    DB.one({:log_visibilities, :fetch}, [log.server_id, log.id, log.revision_id])
  end

  # If this is useful here, move to a util because it will be useful elsewhere
  defp on_error_add_step({:ok, _} = r, _), do: r
  defp on_error_add_step({:error, reason}, step), do: {:error, reason, step}
end
