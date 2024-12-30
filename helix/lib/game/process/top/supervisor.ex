defmodule Game.Process.TOP.Supervisor do
  use DynamicSupervisor

  alias Game.Process.TOP

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def create({server_id, universe, universe_shard_id}) do
    DynamicSupervisor.start_child(__MODULE__, {TOP, {server_id, universe, universe_shard_id}})
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 100)
  end
end
