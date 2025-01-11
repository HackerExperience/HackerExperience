defmodule Game.Events.TOP do
  defmodule Recalcado do
    @moduledoc """
    The TOPRecalcado event indicates that the existing TOP allocations have changed, meaning that
    at least one of the processes had one of its attributes changed in any way.

    This _may_ indicate that we should publish these changes (in full or just the delta -- up to
    the implementation) to the clients, so they can display the new TOP schedule.
    """
    use Core.Event.Definition

    alias Game.{Process, Server}

    defstruct [:server_id, :processes]

    @type t :: %__MODULE__{
            server_id: Server.id(),
            processes: [Process.t()]
          }

    @name :top_recalcado

    def new(%Server.ID{} = server_id, processes) when is_list(processes) do
      %__MODULE__{server_id: server_id, processes: processes}
      |> Event.new()
    end

    # TODO: Publishable
  end
end
