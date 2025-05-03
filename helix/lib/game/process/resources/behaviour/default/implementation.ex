defmodule Game.Process.Resources.Behaviour.Default.Implementation do
  alias Game.Process
  alias Game.Process.Resources.Utils, as: ResourceUtils

  @behaviour Game.Process.Resources.Behaviour

  @type name :: :cpu | :ram | :dlk | :ulk
  @type v :: Decimal.t()

  @zero Decimal.new(0)
  @error_threshold Decimal.new("0.0001")

  @spec initial(name) :: v
  def initial(_), do: build(@zero)

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
  def allocate_static(res, %{status: status, resources: %{static: static}}) do
    static_key = if status == :paused, do: :paused, else: :running

    static
    |> Map.fetch!(static_key)
    |> Map.get(res, initial(res))
  end

  @spec allocate_dynamic(name, v, v, Process.t()) ::
          v
  def allocate_dynamic(res, shares, res_per_share, %{resources: %{dynamic: dynamic_res}}) do
    if res in dynamic_res do
      mul(res, shares, res_per_share)
    else
      initial(res)
    end
  end

  @spec get_shares(name, Process.t()) ::
          v
  def get_shares(res, %{priority: priority, resources: %{dynamic: dynamic_res} = resources}) do
    with true <- res in dynamic_res,
         true <- can_allocate?(res, resources) do
      priority
    else
      _ ->
        initial(res)
    end
  end

  @spec resource_per_share(name, v, v) ::
          v
  def resource_per_share(res, available_resources, shares) do
    res_per_share = div(res, available_resources, shares)

    # Ensure it's a valid value (not negative)
    if Decimal.gt?(res_per_share, @zero) do
      res_per_share
    else
      @zero
    end
  end

  @spec overflow?(name, v) ::
          boolean
  def overflow?(_, %Decimal{} = v), do: Decimal.compare(v, @zero, @error_threshold) == :lt

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
  def sum(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.add(a, b)

  @spec sub(name, v, v) :: v
  def sub(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.sub(a, b)

  @spec mul(name, v, v) :: v
  def mul(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.mult(a, b)

  @spec div(name, v, v) :: v
  def div(res, %Decimal{} = a, %Decimal{} = b),
    do: ResourceUtils.safe_div(a, b, fn -> initial(res) end)

  ##################################################################################################
  # Internal
  ##################################################################################################

  defp build(%Decimal{} = v), do: v

  defp can_allocate?(_, %{processed: nil}),
    do: true

  defp can_allocate?(res, %{processed: processed, objective: objective}),
    do: Decimal.gt?(Map.fetch!(objective, res), Map.get(processed, res, @zero))
end
