defmodule Core.Event.Handler.Behaviour do
  @type data :: map()

  # TODO
  @type event :: map()

  @callback on_event(data(), event()) ::
              :ok
              | {:ok, event() | [event()]}
              | :error
              | {:error, event() | [event()]}
              | {:error, error_details :: term(), event() | [event()]}

  @callback on_rollback(data(), event(), details :: term()) :: [event()]

  @optional_callbacks on_rollback: 3
end
