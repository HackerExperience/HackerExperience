defmodule Helix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DB.Supervisor, name: DB.Supervisor}
    ]

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
