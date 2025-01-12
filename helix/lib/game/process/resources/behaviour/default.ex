defmodule Game.Process.Resources.Behaviour.Default do
  defmacro __using__(_) do
    quote do
      @behaviour Game.Process.Resources.Behaviour
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    # This weird module definition is to avoid transitive compile-time dependencies
    implementation = :"Elixir.Game.Process.Resources.Behaviour.Default.Implementation"

    # Modules `use`-ing this one will have an identical interface (delegated to here)
    for {fn_name, arity} <- implementation.__info__(:functions) do
      case arity do
        1 ->
          quote do
            defdelegate unquote(fn_name)(a), to: unquote(implementation)
          end

        2 ->
          quote do
            defdelegate unquote(fn_name)(a, b), to: unquote(implementation)
          end

        3 ->
          quote do
            defdelegate unquote(fn_name)(a, b, c), to: unquote(implementation)
          end

        4 ->
          quote do
            defdelegate unquote(fn_name)(a, b, c, d), to: unquote(implementation)
          end
      end
    end
  end
end
