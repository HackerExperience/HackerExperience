defmodule Game.Process.Log.Edit do
  use Game.Process.Definition

  defstruct [:log_type, :log_data]

  def new(%{type: log_type, data: log_data}, _) do
    %__MODULE__{
      log_type: log_type,
      log_data: log_data
    }
  end

  def get_process_type(_params, _meta) do
    :log_edit
  end

  def on_db_load(%__MODULE__{} = raw) do
    raw
    |> Map.put(:log_type, String.to_existing_atom(raw.log_type))
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _params) do
      # TODO
      5000
    end

    #
    def dynamic(_, _), do: [:cpu]

    def static(_, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
    alias Game.Log

    @type meta ::
            %{
              log: Log.t()
            }

    def target_log(_server_id, _entity_id, _params, %{log: log}, _),
      do: log
  end
end
