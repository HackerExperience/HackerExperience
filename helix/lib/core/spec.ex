defmodule Core.Spec do
  import Norm

  def binary, do: spec(is_binary())
  def integer, do: spec(is_integer())
end
