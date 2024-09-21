defmodule Core.Schema do
  defmacro __using__(_opts) do
    quote do
      use DB.Schema

      import DB.Schema,
        only: [add_error: 3, validate: 2, validate_fields: 2]

      alias DB.Schema
      import unquote(__MODULE__)
    end
  end

  @doc """
  Pure syntactic sugar.
  """
  defmacro validator(do: _block) do
    parent_module = __CALLER__.module
    module_name = Module.concat(parent_module, "Validator")

    quote do
      @moduledoc """
      Validations for the #{unquote(module_name)} model.
      """
      defmodule unquote(module_name) do
        raise "Unused"
        # unquote(block)
        # def str_length(v), do: HELL.Utils.String.fast_length(v)
      end
    end
  end
end
