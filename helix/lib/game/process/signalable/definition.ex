defmodule Game.Process.Signalable.Definition do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    signal_handlers =
      [
        {:on_sigterm, quote(do: :delete)},
        {:on_sigstop, quote(do: :pause)},
        {:on_sigcont, quote(do: :resume)},
        {:on_sig_renice, quote(do: :renice)}
      ]

    for {definition, default_value} <- signal_handlers do
      quote do
        if not Module.defines?(__MODULE__, {unquote(definition), 2}) do
          def unquote(definition)(_, _), do: unquote(default_value)
        end
      end
    end
  end
end
