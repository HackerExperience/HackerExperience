defmodule Game.Process.Scanner.Edit do
  use Game.Process.Definition

  defstruct [:instance_id, :target_params]

  def new(%{target_params: target_params}, %{instance: instance}) do
    %__MODULE__{instance_id: instance.id, target_params: target_params}
  end

  def get_process_type(_params, _meta) do
    :scanner_edit
  end

  def on_db_load(%__MODULE__{target_params: %params_mod{}} = raw_data) do
    raw_data
    |> Map.put(:target_params, params_mod.on_db_load(raw_data.target_params))
  end

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.Scanner.InstanceEdited, as: ScannerInstanceEditedEvent
    alias Game.Events.Scanner.InstanceEditFailed, as: ScannerInstanceEditFailedEvent

    def on_complete(%{data: %{instance_id: instance_id, target_params: target_params}} = process) do
      with {true, %{entity: entity}} <- Henforcers.Server.has_access?(process),
           {true, %{instance: instance}} <- Henforcers.Scanner.can_edit?(entity, instance_id),
           {true, _} <- Henforcers.Scanner.valid_params?(instance, target_params),
           {:ok, instance} <- Svc.Scanner.retarget_instance(instance, target_params) do
        {:ok, ScannerInstanceEditedEvent.new(instance, process)}
      else
        {false, henforcer_error, _} ->
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to edit scanner: #{reason}")
          {:error, ScannerInstanceEditFailedEvent.new(reason, process)}

        {:error, reason} ->
          reason = format_henforcer_error(reason)
          Logger.error("Unable to edit scanner: #{reason}")
          {:error, ScannerInstanceEditFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error({:server, :not_belongs}), do: "server_not_belongs"
    defp format_henforcer_error({:instance, :not_found}), do: "instance_not_found"
    defp format_henforcer_error({:tunnel, :not_found}), do: "tunnel_not_found"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def time(_, _, _), do: 5
    def dynamic(_, _, _), do: []
    def static(_, _, _), do: %{paused: %{ram: 1}, running: %{ram: 1}}
  end

  defmodule Executable do
    # There is no "tgt_instance_id" here because there's no value in having a global index of which
    # processes are affecting which instances. This global index is used for triggers and hooks that
    # affect the game mechanics, but for ScannerEditProcess specifically we can ignore them.
    # Imagine the following scenario:
    # - Player starts ScannerEditProcess
    # - Before the process finishes, player closes the Tunnel.
    # - Instances are deleted
    # - ScannerEditProcess completes
    # It is the process responsibility to handle that particular scenario and perform a no-op. We
    # don't need to kill the process upon tunnel closure. There is no need to add another global
    # index for the ProcessRegistry if the Process can handle the scenario gracefully with no
    # degradation or worsened UX exposed to the user.
  end

  defmodule Viewable do
    use Game.Process.Viewable.Definition
    alias Game.{Entity}

    def spec do
      selection(
        schema(%{
          instance_id: external_id()
        }),
        [:instance_id]
      )
    end

    def render_data(%{data: %{instance_id: instance_id}} = process, _, %Entity.ID{} = entity_id) do
      instance_eid = ID.to_external(instance_id, entity_id, process.server_id)
      %{instance_id: instance_eid}
    end
  end
end
