defmodule Game.Scanner.Scanneable do
  alias Game.Scanner.Log, as: LogScanner
  alias Game.ScannerTask

  @behaviour __MODULE__

  @callback retarget(ScannerTask.t()) ::
              {:ok, target_id :: term(), duration :: integer()}
              | {:ok, :empty}

  def retarget(%ScannerTask{type: :log} = task),
    do: LogScanner.retarget(task)

  def retarget(%{type: _}) do
    raise "TODO"
    {:ok, :empty}
  end
end
