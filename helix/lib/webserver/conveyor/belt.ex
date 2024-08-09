defmodule Webserver.Conveyor.Belt do
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  # TODO
  @type request :: map()

  # TODO
  @type conveyor :: map()

  @callback call(request(), conveyor(), params :: map() | nil) :: request()
end
