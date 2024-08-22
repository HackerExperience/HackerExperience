defmodule Core.Event.Publishable do
  use Core.Event.Handler
  alias Feeb.DB
  alias Core.Session.State.SSEMapping
  alias Game.Services, as: Svc

  defmacro __using__(_) do
    quote do
      @behaviour Core.Event.Publishable.Behaviour
    end
  end

  @impl Core.Event.Handler.Behaviour
  def on_event(%ev_mod{}, ev) do
    publishable_mod = get_publishable_mod(ev_mod)

    whom_to_publish = apply(publishable_mod, :whom_to_publish, [ev])

    payload = apply(publishable_mod, :generate_payload, [ev])

    # TODO
    raw_payload =
      case payload do
        {:ok, data} ->
          :json.encode(data) |> to_string()
      end

    # We need Universe DB access for `get_pids_to_publish`
    begin_universe_connection()
    pids_to_publish = get_pids_to_publish(whom_to_publish)
    # TODO: Consider a different API for read-only DB connections that don't need to commit
    DB.commit()

    # For each pid, send the `raw_payload`
    pids_to_publish
    |> Task.async_stream(fn pid -> Webserver.SSE.send_message(pid, raw_payload) end)
    |> Stream.run()

    :ok
  end

  defp get_pids_to_publish(whom_to_publish) do
    whom_to_publish
    |> Enum.reduce([], fn
      {:player, player_id}, acc when is_integer(player_id) ->
        [get_pid_for_player(player_id) | acc]
    end)
    |> List.flatten()
  end

  defp get_pid_for_player(player_id) when is_integer(player_id) do
    %{external_id: player_eid} = Svc.Player.fetch(by_id: player_id)
    SSEMapping.get_player_subscriptions(player_eid)
  end

  defp begin_universe_connection do
    universe = Process.get(:helix_universe)
    shard_id = Process.get(:helix_universe_shard_id)
    DB.begin(universe, shard_id, :read)
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

  defp get_publishable_mod(ev_mod), do: Module.concat(ev_mod, Publishable)
end
