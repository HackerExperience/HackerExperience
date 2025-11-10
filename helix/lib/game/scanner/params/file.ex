defmodule Game.Scanner.Params.File do
  defstruct []

  def cast(_) do
    {:ok, %__MODULE__{}}
  end

  def on_db_load(params) do
    params
  end

  def empty?(%__MODULE__{}), do: true
end
