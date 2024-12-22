defmodule Game.Services.Log do
  require Logger
  alias Feeb.DB
  alias Game.{Log, LogVisibility}

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id_and_revision_id: &query_by_id_and_revision_id/1,
      by_id: {:one, {:logs, :fetch_latest_by_id}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  # TODO: Rethink how (and if) I need to switch context when calling read queries
  # Why not follow the same pattern as inserts?
  # Outside == universe, inside == custom
  def list(filter_params, opts \\ []) do
    # TODO: How can I add LIMIT to "static" queries?
    filters = [
      visible_on_server: {:all, {:log_visibilities, :by_server_ordered}, format: :raw}
      # visible_on_server: &query_by_log_visibility/1
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def create_new(entity_id, server_id, log_params) do
    Core.with_context(:server, server_id, :write, fn ->
      [last_inserted_id] =
        DB.one({:logs, :get_last_inserted_id}, [], format: :raw)

      params =
        log_params
        |> Map.put(:id, (last_inserted_id || 0) + 1)
        |> Map.put(:revision_id, 1)

      with {:ok, log} <- insert_log(server_id, params),
           {:ok, _log_visibility} <- insert_visibility(entity_id, server_id, log) do
        {:ok, log}
      else
        error ->
          Logger.error("Unable to create new log: #{inspect(error)}")
          error
      end
    end)
  end

  def create_revision() do
  end

  defp insert_log(server_id, params) do
    Core.with_context(:server, server_id, :write, fn ->
      params
      |> Log.new()
      |> DB.insert()
      |> on_error_add_step(:log)
    end)
  end

  defp insert_visibility(entity_id, server_id, %Log{} = log) do
    Core.with_context(:player, entity_id, :write, fn ->
      %{
        server_id: server_id,
        log_id: log.id,
        revision_id: log.revision_id
      }
      |> LogVisibility.new()
      |> DB.insert()
      |> on_error_add_step(:log_visibility)
    end)
  end

  defp query_by_id_and_revision_id({log_id, revision_id}) do
    DB.one({:logs, :fetch_by_id_and_revision_id}, [log_id, revision_id])
  end

  # If this is useful here, move to a util because it will be useful elsewhere
  defp on_error_add_step({:ok, _} = r, _), do: r
  defp on_error_add_step({:error, reason}, step), do: {:error, reason, step}
end
