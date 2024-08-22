defmodule Test.Event do
  @table :processed_events

  def on_start do
    :ets.new(@table, [:set, :public, :named_table])
  end

  def wait_events(opts) do
    key_filter =
      cond do
        x_request_id = Keyword.get(opts, :x_request_id) ->
          fn {{_, _, x_req_id}, _} -> x_req_id == x_request_id end

        request_id = Keyword.get(opts, :request_id) ->
          fn {{_, req_id, _}, _} -> req_id == request_id end

        event_id = Keyword.get(opts, :event_id) ->
          fn {{ev_id, _, _}, _} -> ev_id == event_id end

        true ->
          raise "You need to specify a filter for `wait_events/1`. Got: #{inspect(opts)}"
      end

    do_wait_events(opts, key_filter, opts[:count] || 1)
  end

  defp do_wait_events(original_opts, key_filter_fn, expected_count, attempts \\ 0) do
    all_entries = :ets.tab2list(@table)

    results =
      Enum.reduce_while(all_entries, [], fn {_key, %{event: event}} = entry, acc ->
        if key_filter_fn.(entry) do
          new_acc = [event | acc]

          if length(new_acc) == expected_count do
            {:halt, new_acc}
          else
            {:cont, new_acc}
          end
        else
          {:cont, acc}
        end
      end)

    cond do
      length(results) == expected_count ->
        results

      attempts == 100 ->
        raise "Couldn't find the event you were waiting for. #{inspect(original_opts)}"

      true ->
        :timer.sleep(15)
        do_wait_events(original_opts, key_filter_fn, expected_count, attempts + 1)
    end
  end
end
