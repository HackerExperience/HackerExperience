defmodule Test.Event do
  alias Game.{Process, Server}

  @table :processed_events

  def on_start do
    :ets.new(@table, [:set, :public, :named_table])
  end

  @doc """
  Waits for a particular event to complete, based on the filtering logic defined in `opts`.

  Returns a list with the events found *or* raises. It should never return an empty list.

  Filtering opts are:
  - x_request_id
  - request_id
  - server_id
  - event_id
  - filter: Custom function that receives the {key, value} of each stored event and should
            return `true` once it finds the event it's looking for.

  Non filtering opts are:
  - count: Number of events to wait for. Defaults to 1.
  """
  def wait_events!(opts) when is_list(opts) do
    key_filter =
      cond do
        x_request_id = Keyword.get(opts, :x_request_id) ->
          fn {{_, _, _, x_req_id}, _} -> x_req_id == x_request_id end

        request_id = Keyword.get(opts, :request_id) ->
          fn {{_, _, req_id, _}, _} -> req_id == request_id end

        server_id = Keyword.get(opts, :server_id) ->
          fn {{_, s_id, _, _}, _} -> s_id == server_id end

        event_id = Keyword.get(opts, :event_id) ->
          fn {{ev_id, _, _, _}, _} -> ev_id == event_id end

        event_name = Keyword.get(opts, :event_name) ->
          fn {_, %{event: %{name: e_name}}} -> e_name == event_name end

        custom_filter = Keyword.get(opts, :filter) ->
          fn {key, value} -> custom_filter.(key, value) end

        true ->
          raise "You need to specify a filter for `wait_events!/1`. Got: #{inspect(opts)}"
      end

    do_wait_events!(opts, key_filter, opts[:count] || 1)
  end

  def refute_events!(opts) when is_list(opts) do
    try do
      # With each attempt being 15ms, this will wait up to 45ms
      events = wait_events!(opts ++ [max_attempts: 3])
      raise "You didn't want me to, but I found the following events:\n\n #{inspect(events)}"
    rescue
      e in RuntimeError ->
        cond do
          e.message =~ "Couldn't find the event you were waiting for" ->
            # That's exactly what `refute_events!` wants: the events to NOT be found
            :ok

          e.message =~ "You were expecting only" ->
            raise e.message

          true ->
            raise e
        end
    end
  end

  def wait_events_on_server!(%Server.ID{} = server_id, event_name, count \\ 1) do
    wait_events!(
      filter: fn
        {_, s_id, _, _}, %{event: %{name: e_name}} ->
          s_id == server_id and e_name == event_name

        _, _ ->
          false
      end,
      count: count
    )
  end

  def refute_events_on_server!(%Server.ID{} = server_id, event_name) do
    refute_events!(
      filter: fn
        {_, s_id, _, _}, %{event: %{name: e_name}} ->
          s_id == server_id and e_name == event_name

        _, _ ->
          false
      end
    )
  end

  def wait_process_completed_event!(%Process{id: process_id, server_id: server_id}) do
    wait_events!(
      filter: fn
        _, %{event: %{name: :process_completed}, data: %{process: process}} ->
          process.server_id == server_id and process.id == process_id

        _, _ ->
          false
      end
    )
  end

  defp do_wait_events!(original_opts, key_filter_fn, expected_count, attempts \\ 0)
       when is_integer(expected_count) do
    all_entries = :ets.tab2list(@table)

    results =
      Enum.reduce(all_entries, [], fn {_key, %{event: event}} = entry, acc ->
        if key_filter_fn.(entry) do
          new_acc = [event | acc]

          if length(new_acc) == expected_count do
            new_acc
          else
            new_acc
          end
        else
          acc
        end
      end)

    cond do
      length(results) > expected_count ->
        raise("You were expecting only #{expected_count} events, found #{length(results)}")

      attempts == (original_opts[:max_attempts] || 100) ->
        raise "Couldn't find the event you were waiting for. #{inspect(original_opts)}"

      length(results) == expected_count ->
        results

      true ->
        :timer.sleep(15)
        do_wait_events!(original_opts, key_filter_fn, expected_count, attempts + 1)
    end
  end
end
