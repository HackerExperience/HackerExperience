defmodule Core.EventTest do
  use Test.DBCase, async: true
  alias Core.Event

  describe "emit/1" do
    test "in the event of an error, displays the proper stacktrace" do
      log =
        capture_log(fn ->
          event = Test.CustomCodeEvent.new(fn -> raise "Something bad" end)
          Event.emit([event])
        end)

      assert log =~ "[error]"
      assert log =~ "Something bad"
      assert log =~ "Failed to execute event Test.CustomCodeEvent on"
      assert log =~ "test/core/event_test.exs"
    end
  end
end
