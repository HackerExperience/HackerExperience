defmodule Helix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {PartitionSupervisor, child_spec: Task.Supervisor, name: Helix.TaskSupervisor},
        {Core.Supervisor, name: Core.Supervisor},
        {Webserver.Supervisor, name: Webserver.Supervisor}
      ]

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
