defmodule Core.Event.Publishable.Behaviour do
  # TODO
  @typep event :: map()

  # TODO
  @typep session :: map()

  # TODO return type
  @callback whom_to_publish(event()) ::
              map()

  @callback generate_payload(event()) ::
              {:ok, payload :: map()}
              | :dynamic
              | :noreply

  # This callback is called when `generate_payload/1` returns `:dynamic`, meaning the payload
  # depends on which player will receive it, hence `generate_payload/2` with the session. Naturally,
  # every call to this function is akin to an N+1 query (but that's not a problem because SQLite).
  @callback generate_payload(event(), session()) ::
              {:ok, payload :: map()}
              | :noreply

  @optional_callbacks generate_payload: 2
end
