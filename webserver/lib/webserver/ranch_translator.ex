defmodule Webserver.RanchTranslator do
  # Translates exceptions from REST endopints
  def translate(
        _min_level,
        :error,
        :format,
        {~c"Ranch listener" ++ _, [_ref, _server_pid, _stream_id, req_pid, reason, stack]}
      ) do
    prefix_msg = "Cowboy request died: #{inspect(req_pid)}\n\n"
    translate_ranch(prefix_msg, reason, stack)
  end

  def translate(_min_level, _level, _kind, _data),
    do: :none

  defp translate_ranch(prefix_msg, reason, stack),
    do: {:ok, [prefix_msg | Exception.format(:error, reason, stack)]}
end
