defmodule Test.Utils.Scanner do
  use Test.Setup.Definition

  alias Game.{ScannerInstance, ScannerTask}

  def get_all_scanner_instances do
    Core.with_context(:scanner, :read, fn ->
      DB.all(ScannerInstance)
    end)
  end

  def get_all_scanner_tasks do
    Core.with_context(:scanner, :read, fn ->
      DB.all(ScannerTask)
    end)
  end

  def get_task_for_scanner_instance(%ScannerInstance{id: instance_id}),
    do: get_task_for_scanner_instance(instance_id)

  def get_task_for_scanner_instance(%ScannerInstance.ID{} = instance_id) do
    get_all_scanner_tasks()
    |> Enum.find(&(&1.instance_id == instance_id))
  end
end
