defmodule DB.Repo.Manager do
  @moduledoc false

  use GenServer
  require Logger

  alias __MODULE__, as: Manager

  # Public API

  def start_link({context, shard_id}) do
    GenServer.start_link(__MODULE__, {context, shard_id})
  end

  def create(context, shard_id) do
    Manager.Supervisor.create(context, shard_id)
  end

  def fetch_connection(manager_pid, type) when type in [:write, :read] do
    GenServer.call(manager_pid, {:fetch, type})
  end

  def release_connection(manager_pid, repo_pid) do
    GenServer.call(manager_pid, {:release, repo_pid})
  end

  def close_connection(manager_pid, repo_pid) do
    GenServer.call(manager_pid, {:close, repo_pid})
  end

  # Server API

  def init({context, shard_id}) do
    Logger.info("Starting repo manager for shard #{shard_id} #{inspect(self())}")

    state = %{
      context: context,
      shard_id: shard_id,
      write_1: %{pid: nil, busy?: false},
      read_1: %{pid: nil, busy?: false},
      read_2: %{pid: nil, busy?: false}
    }

    {:ok, state, {:continue, :notify_registry}}
  end

  def handle_continue(:notify_registry, state) do
    :ok = Manager.Registry.notify_alive(state.context, state.shard_id)
    {:noreply, state}
  end

  def handle_call({:fetch, mode}, _from, state) do
    case fetch_or_create_connection(mode, state) do
      {:ok, repo_pid, new_state} ->
        {:reply, {:ok, repo_pid}, new_state}

      {:busy, new_state} ->
        {:reply, :busy, new_state}

      {:error, new_state} ->
        {:reply, :error, new_state}
    end
  end

  def handle_call({:release, repo_pid}, _from, state) do
    case do_release_connection(state, repo_pid) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, _} ->
        {:reply, :error, state}
    end
  end

  def handle_call({:close, repo_pid}, _from, state) do
    with {:ok, new_state} <- do_release_connection(state, repo_pid),
         {:ok, new_state} <- do_close_connection(new_state, repo_pid) do
      {:reply, :ok, new_state}
    else
      e ->
        Logger.error("Unable to close connection from Repo.Manager: #{inspect(e)}")

        {:reply, :error, state}
    end
  end

  defp fetch_or_create_connection(:write, state) do
    cond do
      is_nil(state.write_1.pid) ->
        establish_connection(state, :write_1)

      not state.write_1.busy? ->
        fetch_available_connection(state, :write_1)

      state.write_1.busy? ->
        # TODO: Instead of polling, notify caller once available
        {:busy, state}
    end
  end

  defp fetch_or_create_connection(:read, state) do
    cond do
      is_nil(state.read_1.pid) ->
        establish_connection(state, :read_1)

      not state.read_1.busy? ->
        fetch_available_connection(state, :read_1)

      is_nil(state.read_2.pid) ->
        establish_connection(state, :read_2)

      not state.read_2.busy? ->
        fetch_available_connection(state, :read_2)

      state.read_2.busy? ->
        # TODO: Instead of polling, notify caller once available
        {:busy, state}
    end
  end

  defp do_release_connection(state, pid) do
    case get_key_from_pid(state, pid) do
      {:ok, key} ->
        {:ok, put_in(state, [key, :busy?], false)}

      :error ->
        Logger.error("Unexpected error; can't find key for #{inspect(pid)}")
        {:error, state}
    end
  end

  defp do_close_connection(state, pid) do
    case get_key_from_pid(state, pid) do
      {:ok, key} ->
        :ok = DB.Repo.close(pid)
        {:ok, put_in(state, [key, :pid], nil)}

      :error ->
        Logger.error("Unexpected error; can't find key for #{inspect(pid)}")
        {:error, state}
    end
  end

  defp get_key_from_pid(%{write_1: %{pid: pid}}, pid), do: {:ok, :write_1}
  defp get_key_from_pid(%{read_1: %{pid: pid}}, pid), do: {:ok, :read_1}
  defp get_key_from_pid(%{read_2: %{pid: pid}}, pid), do: {:ok, :read_2}
  defp get_key_from_pid(_, _), do: :error

  defp establish_connection(
         %{shard_id: shard_id, context: context} = state,
         key
       ) do
    mode = if(key == :write_1, do: :readwrite, else: :readonly)
    db_path = DB.Repo.get_path(context, shard_id)

    # REVIEW: Do I really want to link both genservers?
    case DB.Repo.start_link({context, shard_id, db_path, mode}) do
      {:ok, repo_pid} ->
        log(:info, "Established and fetched #{mode} connection", state)
        {:ok, repo_pid, Map.put(state, key, %{pid: repo_pid, busy?: true})}

      error ->
        log(
          :error,
          "Error creating #{mode} connection: #{inspect(error)}",
          state
        )

        {:error, state}
    end
  end

  defp fetch_available_connection(state, key) do
    pid = get_in(state, [key, :pid])
    # log(:info, "Fetched #{key} connection - #{inspect(pid)}", state)
    {:ok, pid, put_in(state, [key, :busy?], true)}
  end

  defp log(level, msg, state, extra_ctx \\ []) do
    log_fn =
      case level do
        :info -> &Logger.info/2
        :warning -> &Logger.warning/2
        :error -> &Logger.error/2
      end

    base_ctx = [pid: self(), shard_id: state.shard_id]

    log_fn.(msg, base_ctx ++ extra_ctx)
  end
end
