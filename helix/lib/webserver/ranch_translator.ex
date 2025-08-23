defmodule Webserver.RanchTranslator do
  # Translates exceptions from REST endopints
  def translate(
        _min_level,
        :error,
        :format,
        {~c"Ranch listener" ++ _, [ref, conn_pid, stream_id, stream_pid, {reason, stack}]}
      ) do
    ctx = {ref, conn_pid, stream_id, stream_pid}
    prefix_msg = "Cowboy request died: #{inspect(ctx)}\n\n"
    translate_ranch(prefix_msg, reason, stack)
  end

  def translate(_min_level, _level, _kind, _data),
    do: :none

  defp translate_ranch(prefix_msg, reason, stack),
    do: {:ok, [prefix_msg, Exception.format(:error, reason, stack)]}
end
