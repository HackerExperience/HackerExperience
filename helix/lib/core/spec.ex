defmodule Core.Spec do
  import Norm

  defmacro __using__(_) do
    quote do
      use Norm
      import unquote(__MODULE__)
    end
  end

  def binary, do: spec(is_binary())
end
