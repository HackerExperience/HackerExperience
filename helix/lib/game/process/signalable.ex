defmodule Game.Process.Signalable do
  alias Game.Process

  @spec sigterm(Process.t(), args :: [term]) ::
          :delete
          | {:retarget, new_objective :: map, registry_changes :: map}
  def sigterm(process, args \\ []),
    do: signal_handler(process, :on_sigterm, args)

  @spec sigstop(Process.t(), args :: [term]) ::
          :pause
          | :noop
  def sigstop(process, args \\ []),
    do: signal_handler(process, :on_sigstop, args)

  @spec sigcont(Process.t(), args :: [term]) ::
          :resume
          | :noop
  def sigcont(process, args \\ []),
    do: signal_handler(process, :on_sigcont, args)

  @spec sig_renice(Process.t(), args :: [term]) ::
          :renice
  def sig_renice(process, args \\ []),
    do: signal_handler(process, :on_sig_renice, args)

  def signal_handler(%Process{data: %process_mod{}} = process, callback, args) when is_list(args) do
    signalable = get_signalable(process_mod)
    apply(signalable, callback, [process.data, process | args])
  end

  defp get_signalable(process_mod),
    do: Module.concat(process_mod, :Signalable)
end
