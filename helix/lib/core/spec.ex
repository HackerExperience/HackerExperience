defmodule Core.Spec do
  import Norm

  def external_id, do: spec(is_binary())
  def nip, do: spec(is_binary())
  def binary, do: spec(is_binary())
  def integer, do: spec(is_integer())
  def boolean, do: spec(is_boolean())
  def map, do: spec(is_map())
end
