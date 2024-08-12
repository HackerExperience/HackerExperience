defmodule HELL.Utils.DateTime do
  def ts_now, do: DateTime.utc_now() |> DateTime.to_unix()
end
