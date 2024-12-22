defmodule Game.Process.Executable.Defaults do
  def custom(_, _, _, _),
    do: %{}

  def target_log(_, _, _, _, _),
    do: nil
end
