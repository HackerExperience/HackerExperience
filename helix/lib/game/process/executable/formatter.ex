defmodule Game.Process.Executable.Formatter do
  alias Game.{File, Log}

  def format(:custom, result) when is_map(result), do: result
  def format(:resources, result) when is_map(result), do: result

  def format(:target_log, log_input), do: %{tgt_log_id: fmt_log(log_input)}
  def format(:source_file, file_input), do: %{src_file_id: fmt_file(file_input)}
  def format(:target_file, file_input), do: %{tgt_file_id: fmt_file(file_input)}

  defp fmt_file(nil), do: nil
  defp fmt_file(%File.ID{} = id), do: id
  defp fmt_file(%File{id: id}), do: id

  defp fmt_log(nil), do: nil
  defp fmt_log(%Log.ID{} = id), do: id
  defp fmt_log(%Log{id: id}), do: id
end
