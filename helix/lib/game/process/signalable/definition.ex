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
        {:on_sig_renice, quote(do: :renice)},
        {:on_sig_src_file_deleted, quote(do: :noop)},
        {:on_sig_tgt_file_deleted, quote(do: :noop)}
      ]

    valid_handler_names = Enum.map(signal_handlers, &elem(&1, 0))

    # Make sure the user is not defining an unknown signal (e.g. due to typos)
    validation_block =
      quote do
        Module.definitions_in(__MODULE__, :def)
        |> Enum.each(fn {fun, arity} ->
          if arity != 2, do: raise("Invalid arity on Signalable: #{inspect(fun)}")

          if fun not in unquote(valid_handler_names),
            do: raise("Invalid Signalable function: #{inspect(fun)}")
        end)
      end

    defaults_block =
      for {definition, default_value} <- signal_handlers do
        quote do
          if not Module.defines?(__MODULE__, {unquote(definition), 2}) do
            def unquote(definition)(_, _), do: unquote(default_value)
          end
        end
      end

    [validation_block] ++ defaults_block
  end
end
