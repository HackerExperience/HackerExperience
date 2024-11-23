defmodule Test.Utils.SSEListener do
  alias Game.Player
  alias Test.Utils, as: U

  def start(%{shard_id: shard_id, db_context: db_context}, %Player{} = player, opts \\ []) do
    jwt = U.jwt_token(uid: player.external_id)

    # TODO: URL/port logic should be in a shared module
    http_port = if db_context == :singleplayer, do: 5001, else: 5002

    test_pid = self()

    spawn(fn ->
      cmd =
        "curl -s -H 'Content-Type: application/json' -H 'test-game-shard-id: #{shard_id}' -N " <>
          "http://localhost:#{http_port}/v1/player/sync?token=#{jwt}"

      port = Port.open({:spawn, cmd}, [:binary, :use_stdio])

      receive do
        {^port, {:data, index_payload}} ->
          # This first event (the index payload from IndexRequested) is sent as a separate message
          # because, usually, the test does not care about it. It simply is an "automatic" event
          # that comes up every time we establish the SSE connection.
          send(test_pid, {:index, event_from_payload(index_payload)})

          # From now on, loop `total_expected_event` times and notify each event to the test
          loop_notify_events(port, test_pid, opts[:total_expected_events] || 1)
      after
        1000 ->
          raise "No event received after 1s"
      end
    end)

    # This sleep timer can be removed once we implement queueing on concurrent writing connections
    # (at the moment, FeebDB simply crashes if there are multiple writers at the same time, however
    # nothing prevents us from waiting until the other writer is done so we can start processing the
    # request).
    # This conflict happens because (usually) you will have the sync request (performed above) in
    # addition to the request done at the test. They happen at the same-ish time, which leads to
    # conflict if they are both `:readwrite` requests.
    :timer.sleep(500)
  end

  defp loop_notify_events(port, test_pid, total_to_notify, total_notified \\ 0) do
    if total_to_notify > total_notified do
      receive do
        {^port, {:data, sse_payload}} ->
          send(test_pid, {:event, event_from_payload(sse_payload)})
          loop_notify_events(port, test_pid, total_to_notify, total_notified + 1)
      after
        1000 ->
          raise "No event received after 1s (inside loop)"
      end
    end
  end

  defp event_from_payload(raw_payload) do
    raw_payload
    |> String.slice(6..-1//1)
    |> String.replace("\n\n", "")
    |> :json.decode()
    |> Renatils.Map.atomify_keys()
  end
end
