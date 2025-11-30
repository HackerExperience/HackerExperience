defmodule Game.Scanner.Supervisor do
  use Supervisor

  alias Game.Scanner.Worker.TaskCompletion, as: TaskCompletionWorker

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    role = Helix.get_role()

    singleplayer_child =
      %{
        id: :task_completion_worker_sp,
        start: {TaskCompletionWorker, :start_link, [[:singleplayer, 1]]}
      }

    multiplayer_child =
      %{
        id: :task_completion_worker_mp,
        start: {TaskCompletionWorker, :start_link, [[:multiplayer, 1]]}
      }

    # Automatically start the TaskCompletionWorker for each universe, provided we are not running
    # tests. Reason being `shard_id=1` does not exist in tests. Tests cover the worker by ad-hoc
    # processes spawned within the context of each test.
    children =
      case {role, Mix.env()} do
        {:lobby, _} -> []
        {_, :test} -> []
        {:singleplayer, _} -> [singleplayer_child]
        {:multiplayer, _} -> [multiplayer_child]
        {:all, _} -> [singleplayer_child, multiplayer_child]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
