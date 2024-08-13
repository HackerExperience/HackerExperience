defmodule Core.Supervisor do
  use Supervisor

  alias Core.Session

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        supervisor(Session.State.Supervisor, [])
      ]

    supervise(children, strategy: :one_for_one)
  end
end
