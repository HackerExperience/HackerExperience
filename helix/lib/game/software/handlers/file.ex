defmodule Game.Handlers.File do
  alias Feeb.DB
  alias Game.Process.TOP
  alias Game.Services, as: Svc
  alias Game.{ProcessRegistry}

  alias Game.Events.File.Deleted, as: FileDeletedEvent

  @behaviour Core.Event.Handler.Behaviour

  def on_event(%FileDeletedEvent{file: file}, _) do
    # Signal affected processes (src_file_id)
    # Obviously TODO. Waiting for Core.Search
    DB.all(ProcessRegistry)
    |> Enum.filter(&(&1.src_file_id == file.id))
    |> Enum.each(fn %{server_id: server_id, process_id: process_id} ->
      Core.with_context(:server, server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process_id)
        |> TOP.signal(:sig_src_file_deleted)
      end)
    end)

    # Signal affected processes (tgt_file_id)
    # Obviously TODO. Waiting for Core.Search
    DB.all(ProcessRegistry)
    |> Enum.filter(&(&1.tgt_file_id == file.id))
    |> Enum.each(fn %{server_id: server_id, process_id: process_id} ->
      Core.with_context(:server, server_id, :read, fn ->
        Svc.Process.fetch!(by_id: process_id)
        |> TOP.signal(:sig_tgt_file_deleted)
      end)
    end)

    :ok
  end
end
