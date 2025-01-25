defmodule Game.Process.File.Transfer do
  use Game.Process.Definition

  require Logger

  alias Game.Server

  defstruct [:transfer_type, :endpoint_id]

  @transfer_types [:upload, :download]

  def new(%{transfer_type: type, endpoint: %Server{} = endpoint}, _) do
    true = type in @transfer_types
    %__MODULE__{transfer_type: type, endpoint_id: endpoint.id}
  end

  # TODO: I could have a different proc type based on transfer type (file_download|upload)
  # Not sure if that will be useful though. For now, assuming not...
  def get_process_type(_, _), do: :file_transfer

  def on_db_load(%__MODULE__{} = raw) do
    raw
    |> Map.put(:transfer_type, String.to_existing_atom(raw.transfer_type))
  end

  defmodule Processable do
    use Game.Process.Processable.Definition

    alias Game.Events.File.Transferred, as: FileTransferredEvent
    alias Game.Events.File.TransferFailed, as: FileTransferFailedEvent

    @spec on_complete(Process.t(:file_transfer)) ::
            {:ok, FileTransferredEvent.event()}
            | {:error, FileTransferFailedEvent.event()}
    def on_complete(
          %{
            server_id: gateway_id,
            entity_id: entity_id,
            data: %{transfer_type: transfer_type, endpoint_id: endpoint_id},
            registry: %{src_file_id: file_id, src_tunnel_id: tunnel_id}
          } = process
        ) do
      # TODO: This should be done at a higher level (automatically for all Processable)
      Core.Event.Relay.set(process)

      target_server_id =
        case transfer_type do
          :download -> gateway_id
          :upload -> endpoint_id
        end

      Core.begin_context(:server, target_server_id, :write)

      with {true, %{entity: entity, gateway: gateway, endpoint: endpoint}} <-
             Henforcers.Server.has_access?(entity_id, endpoint_id, tunnel_id),
           transfer_info = {transfer_type, gateway, endpoint},
           {true, %{file: file}} <- Henforcers.File.can_transfer?(file_id, entity, transfer_info),
           {:ok, new_file} <- Svc.File.transfer(file, transfer_info) do
        Core.commit()
        {:ok, FileTransferredEvent.new(new_file, transfer_info, process)}
      else
        {false, henforcer_error, _} ->
          Core.rollback()
          reason = format_henforcer_error(henforcer_error)
          Logger.error("Unable to transfer file: #{reason}")
          {:error, FileTransferFailedEvent.new(reason, process)}

        {:error, reason} ->
          Core.rollback()
          Logger.error("Unable to transfer file: #{inspect(reason)}")
          {:error, FileTransferFailedEvent.new(:internal, process)}
      end
    end

    defp format_henforcer_error(unhandled_error), do: "#{inspect(unhandled_error)}"
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    # TODO: dlk/ulk
    def dlk(_factors, _param, _meta) do
      # TODO
      5000
    end

    def limit(_factors, _params, _meta) do
      # TODO: Query endpoint to figure out proper limits
      %{}
    end

    # TODO dlk/ulk based on direction
    def dynamic(_, %{transfer_type: :download}, _), do: [:dlk]
    def dynamic(_, %{transfer_type: :upload}, _), do: [:dlk]

    def static(_, _, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
    alias Game.File

    # TODO: Maybe here is the place I create an FTP connection?
    # Like: def src_connection: {:create, connection_params}

    def source_file(server_id, _entity_id, params, %{file: %File{} = file}, _) do
      case params.transfer_type do
        :download ->
          # Sanity check: if I'm downloading, then the file *must* be in the Endpoint
          true = file.server_id == params.endpoint.id

        :upload ->
          # Sanity check: if I'm uploading, then the file *must* be in the Gateway
          true = file.server_id == server_id
      end

      file
    end
  end
end
