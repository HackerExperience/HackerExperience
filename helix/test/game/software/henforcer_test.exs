defmodule Game.Henforcers.SoftwareTest do
  use Test.DBCase, async: true
  alias Game.Henforcers.Software, as: Henforcer

  describe "type_exists?/1" do
    test "succeeds when software type exists" do
      assert {true, relay} = Henforcer.type_exists?(:cracker)
      assert relay.software.type == :cracker
      assert relay.software.extension == :crc
      assert_relay(relay, [:software])

      assert {true, relay} = Henforcer.type_exists?(:log_editor)
      assert relay.software.type == :log_editor
      assert relay.software.extension == :log
      assert_relay(relay, [:software])
    end

    test "fails when software type does not exist" do
      assert {false, {:software_type, :not_found}, %{}} ==
               Henforcer.type_exists?(:invalid_software_type)
    end
  end

  describe "type_appstore_installable?/1" do
    test "succeeds when software type is appstore installable" do
      assert {true, relay} = Henforcer.type_appstore_installable?(:cracker)
      assert relay.software.type == :cracker
      assert relay.software.extension == :crc
      assert Map.has_key?(relay.software.config, :appstore)
      assert_relay(relay, [:software])
    end

    test "fails when software type does not exist" do
      assert {false, {:software_type, :not_found}, %{}} ==
               Henforcer.type_appstore_installable?(:invalid_software_type)
    end

    test "fails when software type exists but is not appstore installable" do
      assert {false, {:software_type, :not_appstore_installable}, %{}} ==
               Henforcer.type_appstore_installable?(:log_editor)
    end
  end
end
