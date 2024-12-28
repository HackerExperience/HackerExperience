defmodule Game.Process.Resources.Utils do
  @spec safe_div(Decimal.t(), Decimal.t(), initial :: (-> number)) ::
          Decimal.t()
          | initial :: term
  def safe_div(dividend, divisor, initial) do
    try do
      Decimal.div(dividend, divisor)
    rescue
      Decimal.Error ->
        initial.()
    end
  end
end
