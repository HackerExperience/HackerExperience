defmodule Game.Services.ScannerTest do
  use Test.DBCase, async: true

  alias Game.Services, as: Svc
  alias Game.{ScannerInstance}

  describe "fetch_instance/2 - by_entity_server_type" do
    test "returns the instance when it exists" do
      i = Setup.scanner_instance!()

      assert i ==
               Svc.Scanner.fetch_instance(by_entity_server_type: [i.entity_id, i.server_id, i.type])
    end

    test "returns empty when there are no results" do
      server_id = R.server_id()
      entity_id = R.entity_id()
      type = Enum.random(ScannerInstance.types())

      refute Svc.Scanner.fetch_instance(by_entity_server_type: [entity_id, server_id, type])
    end
  end

  describe "list_instances/2 - by_entity_server" do
    test "returns a list of matching instances" do
      server_id = R.server_id()
      entity_id = R.entity_id()

      instances = Setup.scanner_instances!(entity_id: entity_id, server_id: server_id)

      assert Enum.sort(instances) ==
               Enum.sort(Svc.Scanner.list_instances(by_entity_server: [entity_id, server_id]))
    end

    test "returns empty when there are no results" do
      server_id = R.server_id()
      entity_id = R.entity_id()

      assert [] == Svc.Scanner.list_instances(by_entity_server: [entity_id, server_id])
    end
  end

  describe "setup_instances/3" do
    test "creates instances (empty initial state)" do
      server_id = R.server_id()
      entity_id = R.entity_id()

      # Create the instances
      assert {:ok, instances, :setup} = Svc.Scanner.setup_instances(entity_id, server_id, nil)

      assert [instance_connection, instance_file, instance_log] = Enum.sort_by(instances, & &1.type)

      # One instance was created per type
      assert instance_connection.type == :connection
      assert instance_file.type == :file
      assert instance_log.type == :log

      # With the expected data
      assert instance_connection.entity_id == entity_id
      assert instance_connection.server_id == server_id
      assert instance_connection.tunnel_id == nil
      assert instance_connection.target_params == %{}

      # A task is created for each instance
      tasks = U.get_all_scanner_tasks()
      assert [task_connection, task_file, task_log] = Enum.sort_by(tasks, & &1.type)

      assert task_connection.instance_id == instance_connection.id
      assert task_connection.type == :connection
      assert task_connection.entity_id == instance_connection.entity_id
      assert task_connection.server_id == instance_connection.server_id
      assert task_connection.run_id

      # By default the task starts with no target
      assert task_connection.target_id == nil
      assert task_connection.next_backoff == nil
      assert task_connection.failed_attempts == 0

      assert task_file.instance_id == instance_file.id
      assert task_log.instance_id == instance_log.id
    end

    test "recreates instances when they have a different tunnel_id" do
      s_id = R.server_id()
      e_id = R.entity_id()
      tunnel_id_1 = R.tunnel_id()
      tunnel_id_2 = R.tunnel_id()

      # Create the instances normally at first
      assert {:ok, instances_1, :setup} = Svc.Scanner.setup_instances(e_id, s_id, tunnel_id_1)
      assert List.first(instances_1).tunnel_id == tunnel_id_1
      tasks_1 = U.get_all_scanner_tasks()

      # Recreates when asked to create on same entity/server target with different tunnel
      assert {:ok, instances_2, :recreated} = Svc.Scanner.setup_instances(e_id, s_id, tunnel_id_2)
      assert List.first(instances_2).tunnel_id == tunnel_id_2
      tasks_2 = U.get_all_scanner_tasks()

      # After all of this, we have only three instances (`instances_2` -- last write wins)
      refute instances_1 == instances_2
      assert instances_2 == U.get_all_scanner_instances()

      # The tasks, too, were recreated
      refute tasks_1 == tasks_2

      # They now point to the newly created instances
      Enum.each(tasks_2, fn task ->
        assert task.instance_id in Enum.map(instances_2, & &1.id)
      end)
    end

    test "performs a no-op when identical instances already exist" do
      server_id = R.server_id()
      entity_id = R.entity_id()
      tunnel_id = R.tunnel_id()

      # Create the instances normally at first
      assert {:ok, instances, :setup} = Svc.Scanner.setup_instances(entity_id, server_id, tunnel_id)

      # Performs a no-op when asked to create the exact same instances
      assert {:ok, instances, :noop} == Svc.Scanner.setup_instances(entity_id, server_id, tunnel_id)
    end

    @tag :capture_log
    test "recreates the instances when an unexpected # of instances is found" do
      lone_instance = Setup.scanner_instance!()

      assert {:ok, recreated_instances, :recreated} =
               Svc.Scanner.setup_instances(lone_instance.entity_id, lone_instance.server_id, nil)

      assert recreated_instances == U.get_all_scanner_instances()
    end
  end

  describe "retarget_instance/2" do
    test "updates instance's `target_params` and recreates its task" do
      instance = Setup.scanner_instance!()
      old_task = Setup.scanner_task!(instance: instance, target_id: 1)
      assert old_task.instance_id == instance.id
      assert old_task.target_id == 1

      # The instance had its `target_params` changed
      new_target_params = %LogParams{type: :file_deleted, direction: :self}
      assert {:ok, instance} = Svc.Scanner.retarget_instance(instance, new_target_params)
      assert instance.target_params == new_target_params

      Core.begin_context(:scanner, :read)

      # The instance has a new task
      new_task = U.get_task_for_scanner_instance(instance)
      refute new_task.run_id == old_task.run_id

      # It has no target and will complete soon
      refute new_task.target_id
      assert new_task.completion_date - Renatils.DateTime.ts_now() <= 5
    end
  end

  describe "destroy_instances/1 - by_entity_server" do
    test "destroys instances" do
      # We have three instances initially
      Setup.scanner_instances()
      assert [i, _, _] = U.get_all_scanner_instances()

      # Destroy 'em!
      assert :ok == Svc.Scanner.destroy_instances(by_entity_server: {i.entity_id, i.server_id})

      # No instances afterwards
      assert [] == U.get_all_scanner_instances()

      # Tasks were deleted too
      assert [] == U.get_all_scanner_tasks()
    end
  end

  describe "destroy_instances/1 - by_tunnel" do
    test "destroys instances" do
      # We have three instances initially
      Setup.scanner_instances(tunnel_id: 1)
      assert [i, _, _] = U.get_all_scanner_instances()
      assert i.tunnel_id

      # Destroy 'em!
      assert :ok == Svc.Scanner.destroy_instances(by_tunnel: i.tunnel_id)

      # No instances afterwards
      assert [] == U.get_all_scanner_instances()

      # Tasks were deleted too
      assert [] == U.get_all_scanner_tasks()
    end
  end
end
