defmodule Game.Process.Executable.Formatter do
  alias Game.{Log}

  def format(:custom, result) when is_map(result), do: result
  def format(:resources, result) when is_map(result), do: result

  def format(:target_log, %Log{id: id}), do: %{tgt_log_id: id}
  def format(:target_log, %Log.ID{} = id), do: %{tgt_log_id: id}
  def format(:target_log, nil), do: %{tgt_log_id: nil}
end
