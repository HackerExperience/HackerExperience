defmodule Test.UnitCase do
  @moduledoc """
  Same as `use ExUnit.Case`, but with built-in imports and aliases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import ExUnit.CaptureLog
      import Test.Setup.Shared
      # import Test.Assertions
      # import Test.Finders
      # import Test.Utils

      alias HELL.{Random, Utils}
      alias Test.Setup
      alias Test.Utils, as: U
    end
  end
end
