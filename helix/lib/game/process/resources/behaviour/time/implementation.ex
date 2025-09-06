defmodule Game.Process.Resources.Behaviour.Time.Implementation do
  alias Game.Process
  alias Game.Process.Resources.Utils, as: ResourceUtils

  # TODO: Whenever possible, just refer to Default Implementation by default (and only override what has
  # actually changed in this module)

  @behaviour Game.Process.Resources.Behaviour

  @type name :: :time
  @type v :: Decimal.t()

  @zero Decimal.new(0)
  @one Decimal.new(1)

  @spec initial(name) :: v
  def initial(_), do: @zero

  @spec empty(name) :: v
  def empty(_), do: @zero

  @spec fmt_value(name, nil | integer | float | Decimal.t()) :: v
  def fmt_value(res, nil), do: initial(res)
  def fmt_value(_, v), do: Renatils.Decimal.to_decimal(v)

  # Generic data manipulation

  @spec op_map(name, v, v, (v, v -> v)) ::
          v
  def op_map(_, a, b, fun),
    do: fun.(a, b)

  @spec map(name, v, (v -> v)) ::
          v
  def map(_, v, fun),
    do: fun.(v)

  @spec reduce(name, v, term, (v, term -> term)) ::
          term
  def reduce(_, v, acc, fun),
    do: fun.(v, acc)

  @spec allocate_static(name, Process.t()) ::
          v
  def allocate_static(_, _), do: @zero

  @spec allocate_dynamic(name, v, v, Process.t()) ::
          v
  def allocate_dynamic(_, _, _, %{status: :paused}), do: @zero
  def allocate_dynamic(_, _, _, %{status: _}), do: @one

  @spec get_shares(name, Process.t()) ::
          v
  def get_shares(_, _), do: @one

  @spec resource_per_share(name, v, v) ::
          v
  def resource_per_share(_, _, _), do: @one

  @spec overflow?(name, v) ::
          boolean
  # Time never overflows
  def overflow?(_, _), do: false

  @spec completed?(name, v, v) ::
          boolean
  def completed?(_, %Decimal{} = processed, %Decimal{} = objective),
    do: Decimal.gte?(processed, objective)

  @spec equal?(name, v, v) ::
          boolean
  def equal?(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.eq?(a, b, "0.0001")

  ##################################################################################################
  # Operations
  ##################################################################################################

  @spec sum(name, v, v) :: v
  def sum(_, %Decimal{} = a, %Decimal{} = b),
    do: Decimal.add(a, b) |> with_limit(@one)

  @spec sub(name, v, v) :: v
  def sub(_, %Decimal{} = a, %Decimal{} = b),
    do: Decimal.sub(a, b) |> with_limit(@one)

  @spec mul(name, v, v) :: v
  def mul(_, %Decimal{} = a, %Decimal{} = b),
    do: Decimal.mult(a, b) |> with_limit(@one)

  @spec div(name, v, v) :: v
  def div(res, %Decimal{} = a, %Decimal{} = b),
    do: ResourceUtils.safe_div(a, b, fn -> initial(res) end) |> with_limit(@one)

  defp with_limit(v, limit) do
    if Decimal.gt?(v, limit), do: limit, else: v
  end
end
