defmodule Core.Event do
  @moduledoc """
  The Helix Event infrastructure

  Helix is heavily event-driven, and this module (and namespace) powers the event system.

  ### Key principles and ideas

  1. Events are realiable

  There should be no "unreliable IO" happening in an event, especially network IO. DB access is
  okay, since it does not go over a network.

  If you need to perform network IO, or anything that may fail in reality and thus require retrying,
  use the Core.Jobs API (to be implemented).

  2. Events are ephemeral and execute only once

  In the scenario where an event fails to execute, we don't do any sort of retries. That's on
  purpose, given the nature of Helix events. Such events rarely fail, and when they do, retrying
  will almost always reproduce the exact same error. Transient errors due to network or disk IO are
  non-existent or unlikely (see point #1 above)

  Once an event is executed (or has failed), it is gone. Everything that should happen as a result
  of that event, should have happened during its execution, based on native triggers and custom
  handlers. A record is left stating that an event happened, but for the sole purpose of debugging.
  """

  require Logger
  alias Feeb.DB
  alias Renatils.Random

  defstruct [:id, :name, :data, :relay]

  @env Mix.env()

  @native_triggers [
    :"Elixir.Core.Event.Loggable",
    :"Elixir.Core.Event.Publishable"
  ]

  @default_behaviour_on_prepare_db {:universe, :read}
  @default_behaviour_teardown_db_on_success :commit
  @default_behaviour_teardown_db_on_failure :rollback

  @doc """
  Creates a new Event.t with the corresponding `data`.
  """
  def new(%ev_mod{} = data) do
    %__MODULE__{
      id: Random.uuid(),
      name: ev_mod.get_name(),
      data: data,
      relay: Process.get(:helix_event_relay)
    }
  end

  @doc """
  Entrypoint function that will emit the given events.

  For each event, it will iterate over them *synchronously* and *orderly*, emiting one after the
  other. This function will recurse untill all events are emitted, including the ones that were
  emitted as a result of the original input.
  """
  def emit([]), do: :ok

  def emit(events) when is_list(events) do
    events
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce([], fn %__MODULE__{} = event, acc ->
      if is_nil(event.relay),
        do: Logger.warning("No relay found for #{inspect(event.__struct__)}")

      event
      |> get_handlers()
      |> Enum.reduce(acc, fn handler_mod, acc_events ->
        # Before dispatching to the handler, `prepare_db/2` will start a transaction, unless
        # instructed otherwise via the `on_prepare_db/2` behaviour callback.
        prepare_db(handler_mod, event)

        # Dispatch the event to the handler
        {result, new_acc_events} = do_emit(handler_mod, event, acc_events)

        # After the event has been processed, teardown the DB transaction. By default, will COMMIT
        # on success and ROLLBACK on failure, but the default behaviour can be changed based on the
        # `teardown_db_on_success/2` and `teardown_db_on_failure/2` callbacks.
        teardown_db(result, handler_mod, event)
        new_acc_events
      end)
    end)
    # Emit any events that were created and returned by the handlers themselves
    |> emit()
  end

  @doc """
  Emits the given `events` in a separate process (supervised by TaskSupervisor).
  """
  def emit_async(events) when is_list(events) do
    # TODO: Find a way to concentrate in a single module "dirty" state like this (see also TOP)
    helix_universe = Process.get(:helix_universe)
    helix_universe_shard_id = Process.get(:helix_universe_shard_id)

    Task.Supervisor.async_nolink(
      {:via, PartitionSupervisor, {Helix.TaskSupervisor, self()}},
      fn ->
        Process.put(:helix_universe, helix_universe)
        Process.put(:helix_universe_shard_id, helix_universe_shard_id)

        {:event_result, emit(events)}
      end
    )
  end

  defp get_handlers(event) do
    custom_handlers = apply(event.data.__struct__, :handlers, [event.data, event])

    native_handlers =
      @native_triggers
      |> Enum.map(fn trigger_mod -> trigger_mod.probe(event) end)
      |> Enum.reject(&is_nil/1)

    custom_handlers ++ native_handlers ++ test_handler()
  end

  if @env == :test do
    defp test_handler, do: [Core.Event.Handler.Test]
  else
    defp test_handler, do: []
  end

  @spec do_emit(module(), event :: map(), [event :: map()]) ::
          {:ok | :error, [event :: map()]}
  defp do_emit(handler_mod, event, acc_events) do
    try do
      case apply(handler_mod, :on_event, [event.data, event]) do
        :ok ->
          {:ok, acc_events}

        {:ok, ok_events} when is_list(ok_events) ->
          {:ok, acc_events ++ ok_events}

        {:ok, %__MODULE__{} = ok_event} ->
          {:ok, acc_events ++ [ok_event]}

        :error ->
          on_emit_error(acc_events, {[], nil}, {event, handler_mod})

        {:error, details, error_events} when is_list(error_events) ->
          on_emit_error(acc_events, {error_events, details}, {event, handler_mod})

        {:error, error_events} when is_list(error_events) ->
          on_emit_error(acc_events, {error_events, nil}, {event, handler_mod})

        {:error, details, %__MODULE__{} = error_event} ->
          on_emit_error(acc_events, {[error_event], details}, {event, handler_mod})

        {:error, %__MODULE__{} = error_event} ->
          on_emit_error(acc_events, {[error_event], nil}, {event, handler_mod})

        invalid_result ->
          event_mod = "#{inspect(event.data.__struct__)}"

          raise "Invalid result returned for event #{event_mod} on #{handler_mod}." <>
                  "\n\n#{inspect(invalid_result, limit: :infinity)}\n"
      end
    rescue
      exception ->
        # If one of the events fail to execute, log the error but keep processing the other events
        event_mod = "#{inspect(event.data.__struct__)}"
        str_exception = "\n\n    #{inspect(exception)}\n"
        stacktrace = Exception.format_stacktrace(__STACKTRACE__)

        "Failed to execute event #{event_mod} on #{handler_mod}: #{str_exception}\n#{stacktrace}"
        |> Logger.error()

        # Note: in the scenario where an event fails to execute, we don't do any sort of retries.
        # That's on purpose, given the nature of Helix events. Such events rarely fail, and when
        # they do, retrying will almost always reproduce the exact same error. Transient errors due
        # to network or disk IO issues are non-existent or unlikely in the Event infrastructure.
        # Notice, however, that tasks that deal with APIs over the network (e.g. sending an email)
        # do require retrying. These tasks do not use regular Core.Events, but instead implement a
        # custom Job processing queue which support retrying.

        # TODO: Here might be a good place to close DB connections if 1) something goes bad and 2)
        # the event had an open connection in the meantime. However, I might want a more robut and
        # generic solution, perhaps with the usage of monitors.
        # DB.close_if_open()

        {:error, acc_events}
    end
  end

  defp prepare_db(handler_mod, event) do
    case on_prepare_db_behaviour(handler_mod, event) do
      {:universe, access_type} -> Core.begin_context(:universe, access_type)
      :skip -> :ok
    end
  end

  defp teardown_db(:ok, handler_mod, event) do
    case teardown_db_on_success_behaviour(handler_mod, event) do
      :commit -> DB.commit()
      :skip -> :ok
    end
  end

  defp teardown_db(:error, handler_mod, event) do
    case teardown_db_on_failure_behaviour(handler_mod, event) do
      # TODO: Actually roll back
      :rollback -> :ok
      :skip -> :ok
    end
  end

  defp on_emit_error(acc_events, {error_events, error_details}, event_context) do
    {:error, acc_events ++ error_events ++ rollback_event(event_context, error_details)}
  end

  defp rollback_event({event, handler_mod}, error_details) do
    if function_exported?(handler_mod, :on_rollback, 3) do
      apply(handler_mod, :on_rollback, [event.data, event, error_details])
    else
      # Event does not implement custom rollback callbacks so we just perform a no-op
      # With "managed DB", Maybe I DB.rollback here?
      []
    end
  end

  defp on_prepare_db_behaviour(handler_mod, event) do
    if function_exported?(handler_mod, :on_prepare_db, 2) do
      handler_mod.on_prepare_db(event.data, event)
    else
      @default_behaviour_on_prepare_db
    end
  end

  defp teardown_db_on_success_behaviour(handler_mod, event) do
    if function_exported?(handler_mod, :teardown_db_on_success, 2) do
      handler_mod.teardown_db_on_success(event.data, event)
    else
      @default_behaviour_teardown_db_on_success
    end
  end

  defp teardown_db_on_failure_behaviour(handler_mod, event) do
    if function_exported?(handler_mod, :teardown_db_on_failure, 2) do
      handler_mod.teardown_db_on_failure(event.data, event)
    else
      @default_behaviour_teardown_db_on_failure
    end
  end
end
