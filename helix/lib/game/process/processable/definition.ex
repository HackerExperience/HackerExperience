defmodule Game.Process.Processable.Definition do
  defmacro __using__(_) do
    quote do
      require Logger
      alias Game.Henforcers
      alias Game.Services, as: Svc
      alias Game.Process

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    required_definitions = [{:on_complete, 1}]

    required_definitions_block =
      for {definition, arity} <- required_definitions do
        quote do
          if not Module.defines?(__MODULE__, {unquote(definition), unquote(arity)}) do
            raise "Missing function #{unquote(definition)} at #{__MODULE__}"
          end
        end
      end

    optional_definitions = [{:on_pause, quote(do: {:ok, []})}]

    optional_definitions_block =
      for {definition, default_value} <- optional_definitions do
        quote do
          if not Module.defines?(__MODULE__, {unquote(definition), 1}) do
            def unquote(definition)(_), do: unquote(default_value)
          end
        end
      end

    required_definitions_block ++ optional_definitions_block
  end
end
