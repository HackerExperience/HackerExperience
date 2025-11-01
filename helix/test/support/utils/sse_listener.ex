defmodule Test.Utils.SSEListener do
  use Docp
  alias Game.Player
  alias Test.Utils, as: U

  @doc """
  Starts a Sync request (using cURL in a separate process) and sends to the `test_pid` any SSE
  messages it receives.
  """
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
          send(test_pid, :proceed)

          # This first event (the index payload from IndexRequested) is sent as a separate message
          # because, usually, the test does not care about it. It simply is an "automatic" event
          # that comes up every time we establish the SSE connection.
          [index_event | other_events] = get_events_from_payload(index_payload)
          send(test_pid, {:index, index_event})

          # It's possible we already got some events (other than the IndexRequested) in this first
          # batch. That's why we need to make sure our `current_count` has a proper start
          current_count =
            case {other_events, opts[:last_event]} do
              {[], _} ->
                0

              {[_ | _], nil} ->
                Enum.count(other_events)

              {[_ | _], target_event} ->
                other_events
                |> Enum.filter(&(&1.name == "#{target_event}"))
                |> Enum.count()
            end

          expected_count = opts[:total_expected_events] || 1

          # We'll loop until one of the conditions defined by test are satisfied. Either:
          # - Loop until `last_event` is received `expected_count` times; or
          # - Loop until `expected_count` events are received.
          if opts[:last_event] do
            loop_until_event(port, test_pid, opts[:last_event], expected_count, current_count)
          else
            loop_until_count(port, test_pid, expected_count, current_count)
          end
      after
        1000 ->
          raise "No event received after 1s"
      end
    end)

    # Block the test from proceeding until SSE is properly set up. This is important because
    # otherwise the request that will be performed by the test may cause a number of race conditions
    # with the Sync request performed in this function. It's just simpler to avoid that entirely.
    receive do
      :proceed ->
        :ok
    after
      1_000 ->
        raise "SSE did not set up correctly"
    end
  end

  @doc """
  Waits for the Event that was handled by `start/2`.
  """
  def wait_sse_event!(name) do
    expected_event_name = "#{name}"

    receive do
      {:event, %{name: ^expected_event_name} = event} ->
        event

      {:index, %{name: ^expected_event_name} = event} ->
        event
    after
      2000 -> raise "SSE event #{name} never arrived"
    end
  end

  # Loop until `target_event` arrived `expected_count` times
  defp loop_until_event(port, test_pid, target_event, expected_count, current_count) do
    if expected_count > current_count do
      receive do
        {^port, {:data, sse_payload}} ->
          events = get_events_from_payload(sse_payload)

          Enum.each(events, fn event ->
            send(test_pid, {:event, event})
          end)

          # Only increment the counter if the target_event was found
          target_event_count =
            events
            |> Enum.filter(&(&1.name == "#{target_event}"))
            |> Enum.count()

          next_current_count = current_count + target_event_count

          loop_until_event(port, test_pid, target_event, expected_count, next_current_count)
      after
        1000 ->
          raise "No event received after 1s (inside loop)"
      end
    end
  end

  # Loop until we've got `expected_count` events
  defp loop_until_count(port, test_pid, expected_count, current_count) do
    if expected_count > current_count do
      receive do
        {^port, {:data, sse_payload}} ->
          events = get_events_from_payload(sse_payload)

          Enum.each(events, fn event ->
            send(test_pid, {:event, event})
          end)

          loop_until_count(port, test_pid, expected_count, current_count + Enum.count(events))
      after
        1000 ->
          raise "No event received after 1s (inside loop)"
      end
    end
  end

  @docp """
  It is possible that multiple events are batched and sent in a single SSE payload, which is why
  this function needs to return a list of events.
  """
  defp get_events_from_payload(raw_payload) do
    raw_payload
    |> String.split("\n\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn single_raw_payload ->
      single_raw_payload
      |> String.slice(6..-1//1)
      |> JSON.decode!()
      |> Renatils.Map.atomify_keys()
    end)
  end
end
