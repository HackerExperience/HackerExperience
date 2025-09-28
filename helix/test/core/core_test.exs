defmodule CoreTest do
  use Test.DBCase, async: true

  alias Feeb.DB

  describe "with_context/3" do
    test "can create a context when there is no external context" do
      refute DB.LocalState.has_current_context?()

      # Now we try to start a new context even though there is no external context
      Core.with_context(:universe, :read, fn ->
        assert true
      end)

      Core.with_context(:server, %{id: Random.int()}, :read, fn ->
        assert true
      end)

      Core.with_context(:player, %{id: Random.int()}, :read, fn ->
        assert true
      end)
    end

    test "supports nested contexts (universe, read)" do
      refute DB.LocalState.has_current_context?()

      Core.begin_context(:universe, :read)
      assert DB.LocalState.has_current_context?()

      Core.with_context(:universe, :read, fn ->
        assert true
      end)
    end

    test "supports nested contexts (universe, write)" do
      refute DB.LocalState.has_current_context?()

      Core.begin_context(:universe, :write)
      assert DB.LocalState.has_current_context?()

      Core.with_context(:universe, :write, fn ->
        assert true
      end)

      # We can commit only once, because even though these are nested contexts, they share the same
      # connection under the hood
      DB.commit()
      assert_raise RuntimeError, fn -> DB.commit() end
    end
  end

  describe "upgrade_to_write/0" do
    test "upgrades from :read to :write (universe)" do
      refute Core.get_current_context()

      Core.begin_context(:universe, :read)
      assert {mode, shard_id, :read} = Core.get_current_context()

      # Upgrade the connection to write
      assert :ok == Core.upgrade_to_write()

      # Now the connection is in write mode
      assert {mode, shard_id, :write} == Core.get_current_context()
      assert mode in [:singleplayer, :multiplayer]
    end

    test "no-op when upgrading from :write to :write (universe)" do
      refute Core.get_current_context()

      Core.begin_context(:universe, :write)
      assert {mode, shard_id, :write} = Core.get_current_context()

      # Attempt to upgrade the connection to write
      assert :ok == Core.upgrade_to_write()

      # It remains the same
      assert {mode, shard_id, :write} == Core.get_current_context()
    end

    test "upgrades from :read to :write (Player)" do
      player =
        Core.with_context(:universe, :write, fn ->
          Setup.player!()
        end)

      # Start with a read-only connection (Player)
      refute Core.get_current_context()
      Core.begin_context(:player, player.id, :read)
      assert {mode, shard_id, :read} = Core.get_current_context()

      # Upgrade the connection to write
      assert :ok == Core.upgrade_to_write()

      # Now the connection is in write mode
      assert {mode, shard_id, :write} == Core.get_current_context()
      assert mode in [:sp_player, :mp_player]
    end

    test "upgrades from :read to :write (Server)" do
      server =
        Core.with_context(:universe, :write, fn ->
          Setup.server!()
        end)

      # Start with a read-only connection (Server)
      refute Core.get_current_context()
      Core.begin_context(:server, server.id, :read)
      assert {mode, shard_id, :read} = Core.get_current_context()

      # Upgrade the connection to write
      assert :ok == Core.upgrade_to_write()

      # Now the connection is in write mode
      assert {mode, shard_id, :write} == Core.get_current_context()
      assert mode in [:sp_server, :mp_server]
    end
  end
end
