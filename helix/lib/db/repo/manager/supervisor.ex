defmodule DB.Repo.Manager.Supervisor do
  @moduledoc false

  use DynamicSupervisor
  alias DB.{Repo}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def create(context, shard_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Repo.Manager, {context, shard_id}}
    )
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
