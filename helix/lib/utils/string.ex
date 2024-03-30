defmodule Utils.String do
  def count(str, needle) do
    # TODO: Benchmark against alternative `String.graphemes` implementation
    str
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  def fast_length(str) do
    str
    |> String.to_charlist()
    |> length()
  end
end
