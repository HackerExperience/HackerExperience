defmodule Core.Session.State.SSEMappingTest do
  use Test.UnitCase, async: true
  alias Core.Session.State.SSEMapping

  setup do
    universe = Enum.random([:singleplayer, :multiplayer])
    Process.put(:helix_universe, universe)
    {:ok, %{universe: universe}}
  end

  describe "subscribe/3" do
    test "inserts the subscription information" do
      player_eid = Random.uuid()
      session_id = Random.uuid()
      pid = self()

      # Previously the ETS table did not have any `player_eid` entry
      assert Enum.empty?(SSEMapping.get_player_sessions(player_eid))

      # Subscribe
      SSEMapping.subscribe(player_eid, session_id, pid)

      # Now it has one
      assert [session_id] == SSEMapping.get_player_sessions(player_eid)
    end

    test "handles multiple subscriptions for the same player" do
      player_eid = Random.uuid()
      session_id_1 = Random.uuid()
      session_id_2 = Random.uuid()
      # Note that, in reality, the PID would be different, but this is irrelevant for the test
      pid = self()

      # Previously the ETS table did not have any `player_eid` entry
      assert Enum.empty?(SSEMapping.get_player_sessions(player_eid))

      # Subscribe with two different sessions
      SSEMapping.subscribe(player_eid, session_id_1, pid)
      SSEMapping.subscribe(player_eid, session_id_2, pid)

      # Both sessions are found
      sessions = SSEMapping.get_player_sessions(player_eid)
      assert Enum.find(sessions, &(&1 == session_id_1))
      assert Enum.find(sessions, &(&1 == session_id_2))

      # If we accidentally insert duplicates, nothing changes/breaks
      SSEMapping.subscribe(player_eid, session_id_1, pid)
      SSEMapping.subscribe(player_eid, session_id_2, pid)
      assert sessions == SSEMapping.get_player_sessions(player_eid)
      assert Enum.count(SSEMapping.get_player_sessions(player_eid)) == 2
    end

    test "does not find entries from another universe" do
      player_eid = Random.uuid()
      session_id = Random.uuid()
      pid = self()

      # Let's insert the player in the Multiplayer universe
      Process.put(:helix_universe, :multiplayer)
      SSEMapping.subscribe(player_eid, session_id, pid)

      # We can find the player in this universe
      assert [session_id] == SSEMapping.get_player_sessions(player_eid)

      # Now for whatever reason we are in a different universe
      Process.put(:helix_universe, :singleplayer)

      # There's nothing here
      assert [] == SSEMapping.get_player_sessions(player_eid)
    end
  end

  describe "get_subscriptions_for_player/1" do
    test "returns the subscriptions (SSE connection pids)" do
      player_eid = Random.uuid()
      session_id_1 = Random.uuid()
      session_id_2 = Random.uuid()
      pid_1 = Process.whereis(Helix.Supervisor)
      pid_2 = self()

      SSEMapping.subscribe(player_eid, session_id_1, pid_1)
      SSEMapping.subscribe(player_eid, session_id_2, pid_2)

      subscriptions = SSEMapping.get_player_subscriptions(player_eid)
      assert Enum.find(subscriptions, &(&1 == pid_1))
      assert Enum.find(subscriptions, &(&1 == pid_2))
    end
  end

  describe "get_sessions_for_player/1" do
    test "returns the sessions (SSE connection pids)" do
      player_eid = Random.uuid()
      session_id_1 = Random.uuid()
      session_id_2 = Random.uuid()
      pid = self()

      SSEMapping.subscribe(player_eid, session_id_1, pid)
      SSEMapping.subscribe(player_eid, session_id_2, pid)

      sessions = SSEMapping.get_player_sessions(player_eid)
      assert Enum.find(sessions, &(&1 == session_id_1))
      assert Enum.find(sessions, &(&1 == session_id_2))
    end
  end

  describe "is_subscribed?/2" do
    test "returns true/false according to whether the session is present" do
      player_eid = Random.uuid()
      session_id = Random.uuid()
      pid = self()

      SSEMapping.subscribe(player_eid, session_id, pid)

      assert SSEMapping.is_subscribed?(player_eid, session_id)
      refute SSEMapping.is_subscribed?(player_eid, Random.uuid())
      refute SSEMapping.is_subscribed?(Random.uuid(), session_id)
      refute SSEMapping.is_subscribed?(Random.uuid(), Random.uuid())
    end
  end
end
