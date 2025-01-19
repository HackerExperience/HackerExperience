defmodule Game.Process.Executable.Defaults do
  def custom(_, _, _, _),
    do: %{}

  def target_log(_, _, _, _, _), do: nil
  def source_file(_, _, _, _, _), do: nil
  def target_file(_, _, _, _, _), do: nil
end
