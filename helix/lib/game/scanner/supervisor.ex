defmodule Game.Scanner.Supervisor do
  use Supervisor

  alias Game.Scanner.Worker.TaskCompletion, as: TaskCompletionWorker

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        %{
          id: :task_completion_worker_sp,
          start: {TaskCompletionWorker, :start_link, [[:singleplayer, 1]]}
        },
        %{
          id: :task_completion_worker_mp,
          start: {TaskCompletionWorker, :start_link, [[:multiplayer, 1]]}
        }
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
