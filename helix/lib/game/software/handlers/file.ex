defmodule Game.Handlers.File do
  alias Game.Process.TOP
  alias Game.Services, as: Svc

  alias Game.Events.File.Deleted, as: FileDeletedEvent

  @behaviour Core.Event.Handler.Behaviour

  def on_event(%FileDeletedEvent{file: file}, _) do
    # Send a SIG_SRC_FILE_DELETED signal to processes that relied on this file (src_file_id)
    Svc.Process.list_registry(by_src_file_id: file.id)
    |> Enum.each(fn %{server_id: server_id, process_id: process_id} ->
      Core.with_context(:server, server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process_id)
        |> TOP.signal(:sig_src_file_deleted)
      end)
    end)

    # Send a SIG_TGT_FILE_DELETED signal to processes that relied on this file (tgt_file_id)
    Svc.Process.list_registry(by_tgt_file_id: file.id)
    |> Enum.each(fn %{server_id: server_id, process_id: process_id} ->
      Core.with_context(:server, server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process_id)
        |> TOP.signal(:sig_tgt_file_deleted)
      end)
    end)

    :ok
  end
end
