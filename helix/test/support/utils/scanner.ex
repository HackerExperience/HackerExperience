defmodule Test.Utils.Scanner do
  use Test.Setup.Definition

  alias Game.{ScannerInstance}

  def get_all_scanner_instances do
    Core.with_context(:scanner, :read, fn ->
      DB.all(ScannerInstance)
    end)
  end
end
