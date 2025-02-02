defmodule Game.Henforcers.Log do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.{Log, Server}

  def log_exists?(%Log.ID{} = log_id, nil, %Server{} = server) do
    # If `revision_id` is nil, just make sure the log itself exists and return the latest rev
    case Svc.Log.fetch(server.id, by_id: log_id) do
      %Log{} = log ->
        Henforcer.success(%{log: log})

      nil ->
        Henforcer.fail({:log, :not_found})
    end
  end
end
