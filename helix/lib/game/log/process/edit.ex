defmodule Game.Process.Log.Edit do
  use Game.Process.Definition

  alias Game.{Log}

  defstruct [:type, :direction, :data]

  def new(%{type: log_type, direction: log_direction, data: log_data}, _) do
    %__MODULE__{
      type: log_type,
      direction: log_direction,
      data: log_data
    }
  end

  def get_process_type(_params, _meta) do
    :log_edit
  end

  def on_db_load(%__MODULE__{} = raw) do
    raw
    |> Map.put(:type, String.to_existing_atom(raw.type))
    |> Map.put(:direction, String.to_existing_atom(raw.direction))
  end

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.Log.Edited, as: LogEditedEvent
    alias Game.Events.Log.EditFailed, as: LogEditFailedEvent

    def on_complete(%{registry: %{tgt_log_id: %Log.ID{} = parent_log_id}} = process) do
      Core.begin_context(:server, process.server_id, :write)

      log_params = Map.from_struct(process.data)

      # TODO: Henforce (validate) log params -- also on endpoint

      with {true, %{entity: entity, target: server}} <- Henforcers.Server.has_access?(process),
           {true, _} <- Henforcers.Log.can_edit?(server, entity, parent_log_id),
           {:ok, log} <- Svc.Log.create_revision(entity.id, server.id, parent_log_id, log_params) do
        Core.commit()
        {:ok, LogEditedEvent.new(log, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to edit log: #{reason}")
          {:error, LogEditFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to edit log: #{inspect(reason)}")
          {:error, LogEditFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
    defp format_henforcer_error({:tunnel, :not_found}), do: "tunnel_not_found"
    defp format_henforcer_error({:log, :not_found}), do: "log_not_found"
    defp format_henforcer_error({:log, :deleted}), do: "log_deleted"
    defp format_henforcer_error({:log_visibility, :not_found}), do: "log_not_found"
    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
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

    def render_data(%{registry: %{tgt_log_id: log_id}} = process, _, %Entity.ID{} = entity_id) do
      log_eid = ID.to_external(log_id, entity_id, process.server_id)
      %{log_id: log_eid}
    end
  end
end
