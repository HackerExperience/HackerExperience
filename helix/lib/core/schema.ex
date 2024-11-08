defmodule Core.Schema do
  defmacro __using__(_opts) do
    quote do
      use Feeb.DB.Schema
      alias Core.ID
    end
  end
end
