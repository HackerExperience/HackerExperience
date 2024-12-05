defmodule Core.Event.Publishable do
  @behaviour Core.Event.Handler.Behaviour

  alias Feeb.DB
  alias Core.Session.State.SSEMapping
  alias Game.Services, as: Svc

  @doc """
  Entrypoint of the Publishable handler.

  Based on the Publishable implementation by the event module, it will push the corresponding
  payload to the SSE connection(s).
  """
  @impl Core.Event.Handler.Behaviour
  def on_event(%ev_mod{}, ev) do
    publishable_mod = get_publishable_mod(ev_mod)

    event_name = apply(ev_mod, :get_name, [])
    whom_to_publish = apply(publishable_mod, :whom_to_publish, [ev])
    data = apply(publishable_mod, :generate_payload, [ev])

    # TODO: Enforce `raw_data` adheres to the contract

    # TODO
    raw_payload =
      case data do
        {:ok, raw_data} ->
          %{
            data: raw_data,
            name: event_name,
            universe: Process.get(:helix_universe)
          }
          |> :json.encode()
          |> to_string()
      end

    pids_to_publish = get_pids_to_publish(whom_to_publish)

    # We are COMMITing the transaction now, so it can be re-used by other requests/events without
    # having to wait for the payload to be published. As a result, we will `:skip` when
    # `teardown_db_on_success/2` is called.
    # TODO: Consider a different API for read-only DB connections that don't need to commit
    DB.commit()

    # For each pid, send the `raw_payload`
    pids_to_publish
    |> Task.async_stream(fn pid -> Webserver.SSE.send_message(pid, raw_payload) end)
    |> Stream.run()

    :ok
  end

  @doc """
  On (successful) teardown, instruct Core.Event to do nothing. We already committed the transaction
  ourselves in the `on-event/2` block.
  """
  @impl Core.Event.Handler.Behaviour
  def teardown_db_on_success(_, _), do: :skip

  defp get_pids_to_publish(whom_to_publish) do
    whom_to_publish
    |> Enum.reduce([], fn
      {:player, %_{id: player_id}}, acc when is_integer(player_id) ->
        [get_pid_for_player(player_id) | acc]
    end)
    |> List.flatten()
  end

  defp get_pid_for_player(player_id) when is_integer(player_id) do
    %{external_id: player_eid} = Svc.Player.fetch(by_id: player_id)
    SSEMapping.get_player_subscriptions(player_eid)
  end

  @doc """
  Given an event, find out if it implements the Publishable trigger.
  """
  def probe(%_{data: %ev_mod{}}) do
    if function_exported?(get_publishable_mod(ev_mod), :whom_to_publish, 1) do
      __MODULE__
    else
      nil
    end
  end

  def get_publishable_mod(ev_mod), do: Module.concat(ev_mod, Publishable)
end
