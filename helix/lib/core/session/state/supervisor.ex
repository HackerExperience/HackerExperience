defmodule Core.Session.State.Supervisor do
  use Supervisor

  alias Core.Session.State

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    role = Helix.get_role()

    singleplayer_child =
      %{
        id: :sse_sp,
        start: {State.SSEMapping, :start_link, [:singleplayer]}
      }

    multiplayer_child =
      %{
        id: :sse_mp,
        start: {State.SSEMapping, :start_link, [:multiplayer]}
      }

    children =
      case role do
        :lobby -> []
        :singleplayer -> [singleplayer_child]
        :multiplayer -> [multiplayer_child]
        :all -> [singleplayer_child, multiplayer_child]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
