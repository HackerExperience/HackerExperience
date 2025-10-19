defmodule Game.Scanner.Supervisor do
  use Supervisor

  alias Game.Scanner.Worker.TaskCompletion, as: TaskCompletionWorker

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Automatically start the TaskCompletionWorker for each universe, provided we are not running
    # tests. Reason being `shard_id=1` does not exist in tests, which cover the worker by ad-hoc
    # processes spawned within the context of each test.
    children =
      if Mix.env() != :test do
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
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
