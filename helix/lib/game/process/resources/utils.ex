defmodule Game.Process.Resources.Utils do
  @zero Decimal.new(0)

  @spec safe_div(Decimal.t(), Decimal.t(), (-> Decimal.t())) ::
          Decimal.t()
  def safe_div(dividend, divisor, initial) do
    if not Decimal.eq?(divisor, @zero) do
      Decimal.div(dividend, divisor)
    else
      initial.()
    end
  end
end
