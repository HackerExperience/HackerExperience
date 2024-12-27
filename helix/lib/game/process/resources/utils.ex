defmodule Game.Process.Resources.Utils do
  def ensure_float(f) when is_float(f), do: f
  def ensure_float(i) when is_number(i), do: (i / 1) |> Float.round(3)
  def ensure_float(map) when map_size(map) == 0, do: 0.0
end
