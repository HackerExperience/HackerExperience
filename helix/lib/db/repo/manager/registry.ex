# TODO: This entire file should be removed. Move to a DynSup and/or ETS
# TODO: This is fine ATM, but if the Registry worker dies we'll lose all references
# Whereas if we were using an ETS table, maybe not really?
# Also, why not simply use an ETS table?
defmodule DB.Repo.Manager.Registry do
  alias __MODULE__

  # TODO: If the Manager dies and restarts, apparently the Registry is not
  # being updated.
  def fetch_or_create(context, shard_id) do
    Registry.Slice.dispatch(context, shard_id, :fetch_or_create, [
      context,
      shard_id
    ])
  end

  def notify_alive(context, shard_id) do
    Registry.Slice.dispatch(context, shard_id, :notify_alive, [shard_id])
  end
end

defmodule DB.Repo.Manager.Registry.Slice do
  @worker DB.Repo.Manager.Registry.Worker

  @slice_list [
    :repo_manager_lobby_registry,
    :repo_manager_test_registry,
    :repo_manager_player_registry_slice_0,
    :repo_manager_player_registry_slice_1,
    :repo_manager_player_registry_slice_2,
    :repo_manager_player_registry_slice_3,
    :repo_manager_player_registry_slice_4,
    :repo_manager_player_registry_slice_5,
    :repo_manager_player_registry_slice_6,
    :repo_manager_player_registry_slice_7,
    :repo_manager_player_registry_slice_8,
    :repo_manager_player_registry_slice_9
  ]

  def list,
    do: @slice_list

  def dispatch(context, entity_id, method, args),
    do: apply(@worker, method, [get_slice_id(context, entity_id) | args])

  defp get_slice_id(context, entity_id) when is_integer(entity_id),
    do: entity_id |> rem(10) |> map_id(context)

  defp map_id(_, :lobby), do: :repo_manager_lobby_registry
  defp map_id(_, :test), do: :repo_manager_test_registry
  defp map_id(0, :player), do: :repo_manager_player_registry_slice_0
  defp map_id(1, :player), do: :repo_manager_player_registry_slice_1
  defp map_id(2, :player), do: :repo_manager_player_registry_slice_2
  defp map_id(3, :player), do: :repo_manager_player_registry_slice_3
  defp map_id(4, :player), do: :repo_manager_player_registry_slice_4
  defp map_id(5, :player), do: :repo_manager_player_registry_slice_5
  defp map_id(6, :player), do: :repo_manager_player_registry_slice_6
  defp map_id(7, :player), do: :repo_manager_player_registry_slice_7
  defp map_id(8, :player), do: :repo_manager_player_registry_slice_8
  defp map_id(9, :player), do: :repo_manager_player_registry_slice_9
end

defmodule DB.Repo.Manager.Registry.Worker do
  use GenServer

  require Logger

  alias DB.Repo.Manager

  @initial_state %{}

  # Client API

  def start_link(slice_id) do
    GenServer.start_link(__MODULE__, [], name: slice_id)
  end

  def fetch_or_create(slice_id, context, shard_id) do
    GenServer.call(slice_id, {:fetch_or_create, context, shard_id})
  end

  def notify_alive(slice_id, shard_id) do
    GenServer.call(slice_id, {:notify_alive, shard_id})
  end

  # Server API

  def init(_), do: {:ok, @initial_state}

  def handle_call({:fetch_or_create, context, shard_id}, _from, state) do
    # IO.puts "handling the"
    # IO.inspect(state)
    # IO.inspect(shard_id)

    case state[shard_id] do
      manager_pid when is_pid(manager_pid) ->
        if Process.alive?(manager_pid) do
          {:reply, {:ok, manager_pid}, state}
        else
          Logger.warning("Registry information is out-of-date for manager #{inspect(manager_pid)}")

          # TODO: Maybe return error here and fix the underlying root issue?
          {:ok, manager_pid} = Manager.create(context, shard_id)
          {:reply, {:ok, manager_pid}, Map.put(state, shard_id, manager_pid)}
        end

      nil ->
        {:ok, manager_pid} = Manager.create(context, shard_id)
        {:reply, {:ok, manager_pid}, Map.put(state, shard_id, manager_pid)}
    end
  end

  def handle_call({:notify_alive, shard_id}, {manager_pid, _}, state) do
    case Map.get(state, shard_id) do
      ^manager_pid ->
        {:reply, :ok, state}

      nil ->
        {:reply, :ok, Map.put(state, shard_id, manager_pid)}

      other_pid ->
        if Process.alive?(other_pid) do
          Logger.error("Multiple active managers detected for shard #{shard_id}")

          Logger.error("Got old=#{inspect(other_pid)} and new=#{inspect(manager_pid)}")

          {:reply, :error, state}
        else
          Logger.info("Updating Manager entry for shard #{shard_id}")

          Logger.info("Old=#{inspect(other_pid)} and new=#{inspect(manager_pid)}")

          {:reply, :ok, Map.put(state, shard_id, manager_pid)}
        end
    end
  end
end

defmodule DB.Repo.Manager.Registry.Supervisor do
  use Supervisor

  alias DB.Repo.Manager.Registry

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      Enum.map(Registry.Slice.list(), fn slice_id ->
        %{
          id: slice_id,
          start: {Registry.Worker, :start_link, [slice_id]}
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
