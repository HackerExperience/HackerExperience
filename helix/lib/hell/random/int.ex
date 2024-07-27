defmodule HELL.Random.Int do
  def int(_opts \\ []) do
    :rand.uniform()
    |> Kernel.*(1_000_000)
    |> trunc()
  end
end
