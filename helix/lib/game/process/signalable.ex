defmodule Game.Process.Signalable do
  alias Game.Process

  @signal_map %{
    sigterm: :on_sigterm
  }

  for {signal, callback} <- @signal_map do
    def unquote(signal)(process, args \\ []) do
      signal_handler(process, unquote(callback), args)
    end
  end

  def signal_handler(%Process{data: %process_mod{}} = process, callback, args) when is_list(args) do
    # TODO: Defaults
    signalable = get_signalable(process_mod)
    apply(signalable, callback, [process.data, process | args])
  end

  defp get_signalable(process_mod),
    do: Module.concat(process_mod, :Signalable)
end
