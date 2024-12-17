defmodule Core.Event.Handler.Behaviour do
  @type data :: map()

  # TODO
  @type event :: map()

  @typedoc """
  Transaction behaviour before delegating the event to a handler. Options are:

  - {:universe, access_type} - BEGIN a Universe transaction with the corresponding access type. This
                               is the default behaviour.
  - :skip - Does not BEGIN a transaction at all.
  """
  @type prepare_db_option ::
          {:universe, :read | :write}
          | :skip

  @typedoc """
  Transaction behaviour after the handler successfully finished executing the event. Options are:

  - :commit - COMMITs the transaction. This is the default behaviour.
  - :skip - Does not COMMIT or do anything at all with the transaction.
  """
  @type teardown_db_success_option ::
          :commit
          | :skip

  @typedoc """
  Transaction behaviour after the handler was unable to successfully execute the event (regardless
  if the error was handled or an exception).

  - :rollback - ROLLBACKs the transaction. This is the default behaviour.
  - :skip - Does not ROLLBACK or do anything at all with the transaction.
  """
  @type teardown_db_failure_option ::
          :rollback
          | :skip

  @callback on_event(data(), event()) ::
              :ok
              | {:ok, event() | [event()]}
              | :error
              | {:error, event() | [event()]}
              | {:error, error_details :: term(), event() | [event()]}

  # TODO: I think probe can be implemented generically by Core.Event, perhaps with the help ofo a
  # `get_module` optional callback.
  @callback probe(event()) ::
              module() | nil

  @callback on_rollback(data(), event(), details :: term()) :: [event()]
  @callback on_prepare_db(data(), event()) :: prepare_db_option
  @callback teardown_db_on_success(data(), event()) :: teardown_db_success_option
  @callback teardown_db_on_failure(data(), event()) :: teardown_db_failure_option

  @optional_callbacks on_rollback: 3,
                      on_prepare_db: 2,
                      teardown_db_on_success: 2,
                      teardown_db_on_failure: 2,
                      probe: 1
end
