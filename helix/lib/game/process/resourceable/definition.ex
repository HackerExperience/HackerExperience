defmodule Game.Process.Resourceable.Definition do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    # Ensure require definitions
    required_definitions = [{:dynamic, 3}, {:static, 3}]

    required_definitions_block =
      for {definition, arity} <- required_definitions do
        quote do
          if not Module.defines?(__MODULE__, {unquote(definition), unquote(arity)}) do
            raise "Missing function #{unquote(definition)} at #{__MODULE__}"
          end
        end
      end

    optional_definitions = [{:limit, quote(do: %{})}]

    optional_definitions_block =
      for {definition, default_value} <- optional_definitions do
        quote do
          if not Module.defines?(__MODULE__, {unquote(definition), 3}) do
            def unquote(definition)(_, _, _), do: unquote(default_value)
          end
        end
      end

    # Add default value for each resource
    resources = [:cpu, :ram, :dlk, :ulk]

    resources_block =
      for resource <- resources do
        quote do
          if not Module.defines?(__MODULE__, {unquote(resource), 3}) do
            def unquote(resource)(_, _, _), do: nil
          end
        end
      end

    required_definitions_block ++ optional_definitions_block ++ resources_block
  end
end
