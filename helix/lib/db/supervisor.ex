defmodule DB.Supervisor do
  @moduledoc false

  use Supervisor
  alias DB.{Repo}

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      Repo.Manager.Supervisor,
      Repo.Manager.Registry.Supervisor,
      {Task, fn -> DB.Boot.run() end}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
