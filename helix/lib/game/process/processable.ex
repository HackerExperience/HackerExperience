defmodule Game.Process.Processable do
  alias Game.Process

  def on_complete(%Process{data: %process_mod{}} = process) do
    processable = get_processable(process_mod)
    apply(processable, :on_complete, [process])
  end

  defp get_processable(process_mod),
    do: Module.concat(process_mod, :Processable)
end
