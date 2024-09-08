defmodule Test.CustomCodeEvent do
  @moduledoc """
  This event allows tests to implement custom callbacks. This module is, at the same time, the
  event and its handler.
  """

  use Core.Event

  defstruct [:callback]

  @name :test_custom_code

  def new(callback) do
    %__MODULE__{callback: callback}
    |> Event.new()
  end

  def handlers(_, _) do
    [__MODULE__]
  end

  def on_event(%__MODULE__{callback: cb}, _) do
    cb.()
  end
end
