defmodule Game.Handlers.Process.TOP do
  alias Game.Events
  alias Game.Process.Processable

  @behaviour Core.Event.Handler.Behaviour

  def on_event(%Events.Process.Completed{process: process}, _) do
    Processable.on_complete(process)
  end

  def on_prepare_db(_, _), do: :skip
  def teardown_db_on_success(_, _), do: :skip
  def teardown_db_on_failure(_, _), do: :skip
end
