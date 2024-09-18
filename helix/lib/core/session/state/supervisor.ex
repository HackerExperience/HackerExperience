defmodule Core.Session.State.Supervisor do
  use Supervisor

  alias Core.Session.State

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        %{
          id: :sse_sp,
          start: {State.SSEMapping, :start_link, [:singleplayer]}
        },
        %{
          id: :sse_mp,
          start: {State.SSEMapping, :start_link, [:multiplayer]}
        }
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
