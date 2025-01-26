defmodule Game.Handlers.FileTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  alias Core.Event
  alias Game.Events.File.Deleted, as: FileDeletedEvent

  describe "on_event/2 - FileDeletedEvent" do
    @tag :capture_log
    test "sends a signal to affected processes" do
      %{server: server} = Setup.server()

      # Both these processes are referring to the same `file` (as source and target, respectively)
      %{process: proc_install, spec: %{file: file}} = Setup.process(server.id, type: :file_install)
      %{process: proc_delete} = Setup.process(server.id, type: :file_delete, spec: [file: file])

      assert proc_install.registry.src_file_id == file.id
      assert proc_delete.registry.tgt_file_id == file.id

      # This process refers to a different file; it should remain unaffected at the end of the test
      %{process: other_process} = Setup.process(server.id, type: :file_install)
      refute other_process.registry.src_file_id == file.id

      DB.commit()

      # Let's simulate the `file` being deleted. Notice we are passing `proc_delete` mostly as a
      # placeholder, it hasn't actually completed yet so it should be killed from the signal
      event = FileDeletedEvent.new(file, proc_delete)
      Event.emit([event])

      # Wait for TOP to process each signal
      wait_events_on_server!(server.id, :process_killed, 2)

      # By now, `proc_install` anjd `proc_delete` should have been killed
      refute Svc.Process.fetch(server.id, by_id: proc_install.id)
      refute Svc.Process.fetch(server.id, by_id: proc_delete.id)

      # But `other_process` should remain unchanged
      assert Svc.Process.fetch(server.id, by_id: other_process.id)

      # There is only 1 process in the Registry (`other_process`)
      assert [_] = U.get_all_process_registries()
    end
  end
end
