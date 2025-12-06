defmodule Game.Process.TOP.Registry do
  require Hotel.Tracer

  alias Game.Process.TOP
  alias Game.Server

  @name :top_registry

  def fetch!(server_id) do
    {:ok, pid} = fetch_or_create(server_id)
    pid
  end

  def fetch_or_create(%Server.ID{} = server_id) do
    universe = Process.get(:helix_universe) || raise "Missing contextj"
    universe_shard_id = Process.get(:helix_universe_shard_id) || raise "Missing context"
    fetch_or_create({server_id, universe, universe_shard_id})
  end

  def fetch_or_create({server_id, universe, universe_shard_id}) do
    Hotel.Tracer.with_span("TOP.Registry.fetch_or_create", fn ->
      case TOP.Supervisor.create({server_id, universe, universe_shard_id}) do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}
      end
    end)
  end

  def name, do: @name

  def start_link_opts do
    [
      keys: :unique,
      name: @name,
      partitions: System.schedulers_online()
    ]
  end
end
