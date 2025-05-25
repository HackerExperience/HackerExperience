defmodule Game.Process.Log.Edit do
  use Game.Process.Definition

  defstruct [:log_type, :log_direction, :log_data]

  def new(%{type: log_type, direction: log_direction, data: log_data}, _) do
    %__MODULE__{
      log_type: log_type,
      log_direction: log_direction,
      log_data: log_data
    }
  end

  def get_process_type(_params, _meta) do
    :log_edit
  end

  def on_db_load(%__MODULE__{} = raw) do
    raw
    |> Map.put(:log_type, String.to_existing_atom(raw.log_type))
    |> Map.put(:log_direction, String.to_existing_atom(raw.log_direction))
  end

  defmodule Processable do
    use Game.Process.Processable.Definition

    def on_complete(_process) do
      # TODO
      # Svc.Log.create_revision()
      :ok
    end
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _params, _meta) do
      # TODO
      5000
    end

    def dynamic(_, _, _), do: [:cpu]

    def static(_, _, _) do
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

  defmodule Viewable do
    use Game.Process.Viewable.Definition
    alias Game.{Entity}

    def spec do
      selection(
        schema(%{
          log_id: external_id()
        }),
        [:log_id]
      )
    end

    def render_data(process, %{log_id: log_id}, %Entity.ID{} = entity_id) do
      log_eid = ID.to_external(log_id, entity_id, process.server_id)
      %{log_id: log_eid}
    end
  end
end
