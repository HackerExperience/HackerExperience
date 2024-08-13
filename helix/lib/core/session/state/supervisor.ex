defmodule Core.Session.State.Supervisor do
  use Supervisor

  alias Core.Session.State

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        worker(State.SSEMapping, [:singleplayer], id: :sse_sp, name: State.SSEMapping.Singleplayer),
        worker(State.SSEMapping, [:multiplayer], id: :sse_mp, name: State.SSEMapping.Multiplayer)
      ]

    supervise(children, strategy: :one_for_one)
  end
end
