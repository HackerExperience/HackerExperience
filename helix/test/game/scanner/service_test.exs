defmodule Game.Services.ScannerTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  alias Game.{ScannerInstance}

  describe "fetch/2 - by_entity_server_type" do
    test "returns the instance when it exists" do
      i = Setup.scanner_instance!()
      assert i == Svc.Scanner.fetch(by_entity_server_type: [i.entity_id, i.server_id, i.type])
    end

    test "returns empty when there are no results" do
      server_id = R.server_id()
      entity_id = R.entity_id()
      type = Enum.random(ScannerInstance.types())

      refute Svc.Scanner.fetch(by_entity_server_type: [entity_id, server_id, type])
    end
  end

  describe "list/2 - by_entity_server" do
    test "returns a list of matching instances" do
      server_id = R.server_id()
      entity_id = R.entity_id()

      instances = Setup.scanner_instances!(entity_id: entity_id, server_id: server_id)

      assert Enum.sort(instances) ==
               Enum.sort(Svc.Scanner.list(by_entity_server: [entity_id, server_id]))
    end

    test "returns empty when there are no results" do
      server_id = R.server_id()
      entity_id = R.entity_id()

      assert [] == Svc.Scanner.list(by_entity_server: [entity_id, server_id])
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
    end

    test "recreates instances when they have a different tunnel_id" do
      s_id = R.server_id()
      e_id = R.entity_id()
      tunnel_id_1 = R.tunnel_id()
      tunnel_id_2 = R.tunnel_id()

      # Create the instances normally at first
      assert {:ok, instances_1, :setup} = Svc.Scanner.setup_instances(e_id, s_id, tunnel_id_1)
      assert List.first(instances_1).tunnel_id == tunnel_id_1

      # Recreates when asked to create on same entity/server target with different tunnel
      assert {:ok, instances_2, :recreated} = Svc.Scanner.setup_instances(e_id, s_id, tunnel_id_2)
      assert List.first(instances_2).tunnel_id == tunnel_id_2

      # After all of this, we have only two instances (`instances_2` -- last write wins)
      refute instances_1 == instances_2
      assert instances_2 == U.get_all_scanner_instances()
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

  describe "destroy_instances/2" do
    test "destroys instances" do
      # We have three instances initially
      Setup.scanner_instances()
      assert [i, _, _] = U.get_all_scanner_instances()

      # Destroy 'em!
      assert :ok == Svc.Scanner.destroy_instances(i.entity_id, i.server_id)

      # Nothing afterwards
      assert [] == U.get_all_scanner_instances()
    end
  end
end
