defmodule Game.Process.TOP.Registry do
  alias Game.Process.TOP

  @name :top_registry

  def fetch_or_create({server_id, universe, universe_shard_id}) do
    case TOP.Supervisor.create({server_id, universe, universe_shard_id}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
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
