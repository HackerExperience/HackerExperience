defmodule Core.Supervisor do
  use Supervisor

  alias Core.Session

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        {Session.State.Supervisor, name: Session.State.Supervisor}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
