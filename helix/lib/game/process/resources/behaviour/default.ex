defmodule Game.Process.Resources.Behaviour.Default do
  alias Game.Process.Resources.Utils, as: ResourceUtils

  @behaviour Game.Process.Resources.Behaviour

  @type t :: number

  defmacro __using__(_) do
    quote do
      @behaviour Game.Process.Resources.Behaviour
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    # Modules `use`-ing this one will have an identical interface (delegated to here)
    for {fn_name, arity} <- unquote(__MODULE__).__info__(:functions) do
      case arity do
        0 ->
          quote do
            defdelegate unquote(fn_name)(), to: unquote(__MODULE__)
          end

        1 ->
          quote do
            defdelegate unquote(fn_name)(a), to: unquote(__MODULE__)
          end

        2 ->
          quote do
            defdelegate unquote(fn_name)(a, b), to: unquote(__MODULE__)
          end
      end
    end
  end

  def initial, do: build(0.0)

  def sum(a, b), do: a + b

  defp build(v), do: ResourceUtils.ensure_float(v)
end
