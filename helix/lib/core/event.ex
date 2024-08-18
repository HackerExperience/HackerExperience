defmodule Core.Event do
  require Logger

  defstruct [:id, :data]

  defmacro __using__(_) do
    quote do
      alias Core.Event
    end
  end

  @doc """
  Creates a new Event.t with the corresponding `data`.
  """
  def new(%_{} = data) do
    # `relay` / tracing information would go here
    %__MODULE__{
      id: "random_id",
      data: data
    }
  end

  def emit([]), do: :ok

  def emit(events) when is_list(events) do
    events
    |> Enum.reduce([], fn %__MODULE__{} = event, acc ->
      event
      |> get_handlers()
      |> Enum.reduce(acc, fn handler_mod, acc_events ->
        do_emit(event, handler_mod, acc_events)
      end)
    end)
    # Emit any events that were created and returned by the handlers themselves
    |> emit()
  end

  defp get_handlers(event) do
    custom_handlers = apply(event.data.__struct__, :handlers, [event.data, event])

    # TODO: These will include a lookup for Publishable, Notificable, Loggable etc
    native_handlers = []

    custom_handlers ++ native_handlers
  end

  defp do_emit(event, handler_mod, acc_events) do
    try do
      case apply(handler_mod, :on_event, [event.data, event]) do
        :ok ->
          acc_events

        {:ok, ok_events} when is_list(ok_events) ->
          acc_events ++ ok_events

        {:ok, %__MODULE__{} = ok_event} ->
          acc_events ++ [ok_event]

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
        str_exception = "\n\n#{inspect(exception, limit: :infinity)}\n"

        "Failed to execute event #{event_mod} on #{handler_mod}: #{str_exception}"
        |> Logger.error()

        # Note: in the scenario where an event fails to execute, we don't do any sort of retries.
        # That's on purpose, given the nature of Helix events. Such events rarely fail, and when
        # they do, retrying will almost always reproduce the exact same error. Transient errors due
        # to network or disk IO issues are non-existent or unlikely in the Event infrastructure.
        # Notice, however, that tasks that deal with APIs over the network (e.g. sending an email)
        # do require retrying. These tasks do not use regular Core.Events, but instead implement a
        # custom Job processing queue which support retrying.

        acc_events
    end
  end

  defp on_emit_error(acc_events, {error_events, error_details}, event_context) do
    acc_events ++ error_events ++ rollback_event(event_context, error_details)
  end

  defp rollback_event({event, handler_mod}, error_details) do
    if function_exported?(handler_mod, :on_rollback, 3) do
      apply(handler_mod, :on_rollback, [event.data, event, error_details])
    else
      # Event does not implement custom rollback callbacks so we just perform a no-op
      []
    end
  end
end
