defmodule Game.Process.Scanner.EditTest do
  use Test.DBCase, async: true

  setup [:with_game_db]

  alias Game.Scanner.Params.Log, as: LogParams

  describe "Processable.on_complete/1" do
    test "updates the ScannerInstance target_params" do
      %{server: server, entity: entity} = Setup.server()
      instance = Setup.scanner_instance!(type: :log, entity_id: entity.id, server_id: server.id)
      task = Setup.scanner_task!(instance: instance, target_id: 1)
      assert task.instance_id == instance.id
      assert task.target_id == 1

      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :scanner_edit,
          spec: [instance: instance, target_params: %LogParams{type: :custom, direction: :self}]
        )

      assert process.data.instance_id == instance.id
      assert process.data.target_params

      DB.commit()

      # Simulate Process being completed
      assert {:ok, event} = U.processable_on_complete(process)

      # After the process has completed, the Instance has a new `target_params`
      Core.begin_context(:scanner, :read)
      new_instance = DB.reload!(instance)

      assert new_instance.target_params.type == :custom
      assert new_instance.target_params.direction == :self

      # The Task that is linked to this Instance had its target nullified
      assert task = U.get_task_for_scanner_instance(instance)
      refute task.target_id

      # The ScannerInstanceEditedEvent will be emitted
      assert event.name == :scanner_instance_edited
      assert event.data.instance.id == instance.id
      assert event.data.process == process

      assert event.relay.source == :process
      assert event.relay.server_id == server.id
      assert event.relay.process_id == process.id
    end

    @tag :capture_log
    test "fails if the ScannerInstance no longer exists" do
      %{nip: gtw_nip, entity: entity} = Setup.server()
      %{server: endpoint, nip: endp_nip} = Setup.server()
      tunnel = Setup.tunnel!(source_nip: gtw_nip, target_nip: endp_nip)

      instances =
        Setup.scanner_instances!(entity_id: entity.id, server_id: endpoint.id, tunnel_id: tunnel.id)

      conn_instance = Enum.find(instances, &(&1.type == :connection))

      process =
        Setup.process!(endpoint.id,
          entity_id: entity.id,
          type: :scanner_edit,
          spec: [instance: conn_instance, target_params: %LogParams{}, tunnel: tunnel]
        )

      DB.commit()

      # Now we'll destroy these instances after the process started but before it finished
      assert :ok == Svc.Scanner.destroy_instances(by_tunnel: tunnel.id)

      # All instances (and tasks) are gone
      assert [] == U.get_all_scanner_instances()
      assert [] == U.get_all_scanner_tasks()

      # A ScannerInstanceEditFailedEvent is emitted
      assert {:error, event} = U.processable_on_complete(process)

      assert event.name == :scanner_instance_edit_failed
      assert event.data.reason == "instance_not_found"

      # No new instances/tasks were created
      assert [] == U.get_all_scanner_instances()
      assert [] == U.get_all_scanner_tasks()
    end
  end

  describe "E2E - Processable" do
    test "upon completion, updates the ScannerInstance target params", ctx do
      %{server: server, entity: entity, player: player, nip: nip} = Setup.server()
      instances = Setup.scanner_instances!(entity_id: entity.id, server_id: server.id)
      file_instance = Enum.find(instances, &(&1.type == :file))

      process =
        Setup.process!(server.id,
          entity_id: entity.id,
          type: :scanner_edit,
          completed?: true,
          spec: [instance: file_instance]
        )

      DB.commit()

      U.start_sse_listener(ctx, player, last_event: :scanner_instance_edited)

      # Complete the Process
      U.simulate_process_completion(process)

      # SSE events were published
      proc_completed_ev = U.wait_sse_event!(:process_completed)
      assert proc_completed_ev.data.process_id |> U.from_eid(player.id) == process.id

      scanner_instance_edited = U.wait_sse_event!(:scanner_instance_edited)
      assert scanner_instance_edited.data.nip == nip |> NIP.to_external()
      assert scanner_instance_edited.data.instance.id |> U.from_eid(player.id) == file_instance.id
      assert scanner_instance_edited.data.instance.type == "file"
    end
  end
end
