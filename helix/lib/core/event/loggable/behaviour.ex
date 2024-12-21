defmodule Core.Event.Loggable.Behaviour do
  @typep event :: map()

  # TODO: Like pretty much everywhere else, typespecs are todo
  @callback log_map(event()) ::
              map()
end
