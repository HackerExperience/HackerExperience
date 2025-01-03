defmodule Game.Process.Resources.Behaviour.Default do
  alias Game.Process.Resources.Utils, as: ResourceUtils

  @behaviour Game.Process.Resources.Behaviour

  @type t :: number

  @zero Decimal.new(0)

  defmacro __using__(_) do
    quote do
      @behaviour Game.Process.Resources.Behaviour
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    # Modules `use`-ing this one will have an identical interface (delegated to here)
    for {fn_name, arity} <- unquote(__MODULE__).__info__(:functions) do
      case arity do
        1 ->
          quote do
            defdelegate unquote(fn_name)(a), to: unquote(__MODULE__)
          end

        2 ->
          quote do
            defdelegate unquote(fn_name)(a, b), to: unquote(__MODULE__)
          end

        3 ->
          quote do
            defdelegate unquote(fn_name)(a, b, c), to: unquote(__MODULE__)
          end

        4 ->
          quote do
            defdelegate unquote(fn_name)(a, b, c, d), to: unquote(__MODULE__)
          end
      end
    end
  end

  ##################################################################################################
  # Callbacks
  ##################################################################################################

  def initial(_), do: build(@zero)

  def fmt_value(res, nil), do: initial(res)
  def fmt_value(_, v), do: Renatils.Decimal.to_decimal(v)

  # Generic data manipulation

  # def reduce(_, resource, initial, fun),
  #   do: fun.(initial, resource)

  # def map(_, resource, fun),
  #   do: fun.(resource)

  def op_map(_, a, b, fun),
    do: fun.(a, b)

  def map(_, v, fun),
    do: fun.(v)

  def reduce(_, v, acc, fun),
    do: fun.(v, acc)

  def allocate_static(res, %{status: status, resources: %{static: static}}) do
    static_key = if status == :paused, do: :paused, else: :running

    static
    |> Map.fetch!(static_key)
    |> Map.get(res, initial(res))
  end

  def allocate_dynamic(res, shares, res_per_share, %{resources: %{l_dynamic: dynamic_res}}) do
    if res in dynamic_res do
      mul(res, shares, res_per_share)
    else
      initial(res)
    end
  end

  def get_shares(res, %{priority: priority, resources: %{l_dynamic: dynamic_res} = resources}) do
    with true <- res in dynamic_res,
         true <- can_allocate?(res, resources) do
      priority
    else
      _ ->
        initial(res)
    end
  end

  def resource_per_share(res, available_resources, shares) do
    res_per_share = div(res, available_resources, shares)

    # Ensure it's a valid value (not negative)
    (res_per_share >= 0 && res_per_share) || 0.0
  end

  def overflow?(_, %Decimal{} = v), do: Decimal.lt?(v, @zero)

  def completed?(_, %Decimal{} = processed, %Decimal{} = objective),
    do: Decimal.gte?(processed, objective)

  ##################################################################################################
  # Operations
  ##################################################################################################

  def sum(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.add(a, b)
  def sub(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.sub(a, b)
  def mul(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.mult(a, b)

  def div(res, %Decimal{} = a, %Decimal{} = b),
    do: ResourceUtils.safe_div(a, b, fn -> initial(res) end)

  def equal?(_, %Decimal{} = a, %Decimal{} = b), do: Decimal.eq?(a, b)

  ##################################################################################################
  # Internal
  ##################################################################################################

  defp build(%Decimal{} = v), do: v

  defp can_allocate?(_, %{processed: nil}),
    do: true

  defp can_allocate?(res, %{processed: processed, objective: objective}),
    do: Decimal.gt?(Map.fetch!(objective, res), Map.get(processed, res, @zero))
end
