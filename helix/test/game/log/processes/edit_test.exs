defmodule Game.Process.Log.EditTest do
  use Test.DBCase, async: true

  alias Game.Log.Data, as: LogData

  setup [:with_game_db]

  describe "Processable.on_complete/1" do
    test "creates a new revision upon completion" do
      %{server: server, entity: entity} = Setup.server()

      parent_log = Setup.log!(server.id, visible_by: entity.id)

      file = Setup.file!(server.id)

      params =
        %{
          type: :file_deleted,
          direction: :self,
          data: LogData.LocalFile.new(%{file: file})
        }

      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :log_edit,
          spec: [log: parent_log, params: params]
        )

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      Core.begin_context(:server, server.id, :read)

      # After the process has completed, a new revision was created
      new_log_revision =
        Svc.Log.fetch!(server.id,
          by_id_and_revision_id: {parent_log.id, parent_log.revision_id.id + 1}
        )

      # The new revision has the expected data
      assert new_log_revision.id == parent_log.id
      assert new_log_revision.revision_id.id == parent_log.revision_id.id + 1
      assert new_log_revision.type == :file_deleted
      assert new_log_revision.direction == :self
      assert new_log_revision.data.file_name == file.name

      # A new visibility was created for this revision
      log_visibilities = U.get_all_log_visibilities(entity.id)

      assert visibility =
               Enum.find(log_visibilities, &(&1.revision_id == new_log_revision.revision_id))

      assert visibility.log_id == parent_log.id
      assert visibility.revision_id == new_log_revision.revision_id
      assert visibility.server_id == server.id
      assert visibility.entity_id == entity.id

      # The parent log remained unchanged
      assert parent_log == DB.reload!(parent_log)

      # The LogEditedEvent will be emitted
      assert event.name == :log_edited
      assert event.data.log == new_log_revision
      assert event.data.process == process

      assert event.relay.source == :process
      assert event.relay.server_id == server.id
      assert event.relay.process_id == process.id
    end

    test "fails if Player has no visibility over Log" do
      %{server: server, entity: entity} = Setup.server()

      log = Setup.log!(server.id)
      process = Setup.process!(server.id, entity_id: entity.id, type: :log_edit, spec: [log: log])
      DB.commit()

      assert {{:error, event}, error_log} = with_log(fn -> U.processable_on_complete(process) end)
      assert error_log =~ "Unable to edit log: log_not_found"

      # A LogDeleteFailedEvent was returned
      assert event.name == :log_edit_failed
      assert event.data.reason == "log_not_found"

      # No new revisions were created
      Core.begin_context(:server, server.id, :read)
      assert [_] = DB.all(Game.Log)
    end
  end

  describe "E2E - Processable" do
    test "upon completion, creates a new revision", ctx do
      %{server: server, entity: entity, player: player, nip: nip} = Setup.server()

      log_rev_1 = Setup.log!(server.id, visible_by: entity.id)
      log_rev_2 = Setup.log!(server.id, id: log_rev_1.id, revision_id: 2, visible_by: entity.id)

      params =
        %{
          type: :custom,
          direction: :self,
          data: %LogData.Text{text: "This is my custom log"}
        }

      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :log_edit,
          completed?: true,
          spec: [log: log_rev_2, params: params]
        )

      DB.commit()

      U.start_sse_listener(ctx, player, last_event: :log_edited)

      # Complete the Process
      U.simulate_process_completion(process)

      # SSE events were published
      proc_completed_sse = U.wait_sse_event!(:process_completed)
      assert proc_completed_sse.data.process_id |> U.from_eid(player.id) == process.id

      log_edited_sse = U.wait_sse_event!(:log_edited)
      assert log_edited_sse.data.nip == nip |> NIP.to_external()
      assert log_edited_sse.data.process_id |> U.from_eid(player.id) == process.id
      assert log_edited_sse.data.log_id |> U.from_eid(player.id) == log_rev_2.id
      assert log_edited_sse.data.type == "custom"
      assert log_edited_sse.data.direction == "self"
      assert log_edited_sse.data.data == "{\"text\":\"This is my custom log\"}"
    end
  end
end
