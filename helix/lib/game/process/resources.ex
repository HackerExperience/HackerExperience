defmodule Game.Process.Resources do
  @zero Decimal.new(0)
  defstruct cpu: @zero, ram: @zero

  @type t ::
          %__MODULE__{
            cpu: number,
            ram: number
          }

  @type name ::
          :cpu
          | :ram

  @resources [
    :cpu,
    :ram
  ]

  @resources_modules Enum.map(@resources, fn resource ->
                       resource_module_name =
                         resource
                         |> to_string()
                         |> String.upcase()
                         |> String.to_atom()

                       {resource, Module.concat(__MODULE__, resource_module_name)}
                     end)
                     |> Map.new()

  def from_map(resources) do
    %__MODULE__{
      ram: fmt_value(:ram, resources[:ram]),
      cpu: fmt_value(:cpu, resources[:cpu])
    }
  end

  defp fmt_value(res, v),
    do: call_resource(res, :fmt_value, [v])

  ##################################################################################################
  # Callbacks
  ##################################################################################################

  @spec initial() ::
          t
  def initial,
    do: dispatch_create(:initial)

  def map(%__MODULE__{} = resources, fun),
    do: dispatch_value(:map, resources, [fun])

  def reduce(%__MODULE__{} = resources, acc, fun),
    do: dispatch(:reduce, resources, [acc, fun])

  def allocate_static(process),
    do: dispatch_create(:allocate_static, [process])

  def allocate_dynamic(%__MODULE__{} = shares, %__MODULE__{} = res_per_share, process),
    do: dispatch_merge(:allocate_dynamic, shares, res_per_share, [process])

  def get_shares(process),
    do: dispatch_create(:get_shares, [process])

  def resource_per_share(%__MODULE__{} = available_resources, %__MODULE__{} = shares),
    do: dispatch_merge(:resource_per_share, available_resources, shares)

  def overflow?(%__MODULE__{} = resources) do
    :overflow?
    |> dispatch(resources)
    |> Enum.reduce({false, []}, fn {res, v}, {_, acc_overflowed_resources} = acc ->
      if v do
        {true, [res | acc_overflowed_resources]}
      else
        acc
      end
    end)
    |> then(fn
      {true, _} = return ->
        return

      {false, []} ->
        false
    end)
  end

  @spec completed?(processed :: t, objective :: t) ::
          true
          | {false, {name(), remaining :: Decimal.t()}}
  def completed?(%__MODULE__{} = processed, %__MODULE__{} = objective) do
    :completed?
    |> dispatch_merge(processed, objective)
    |> Map.from_struct()
    |> Enum.reduce_while(true, fn {res, res_completed?}, acc ->
      if res_completed? do
        {:cont, true}
      else
        # TODO: Test this branch
        diff = sub(objective, processed)
        {:halt, {res, diff.res}}
      end
    end)
  end

  @doc """
  Returns the resource with the gratest value.
  """
  @spec max_value(t) ::
          {name, Decimal.t()}
  def max_value(%__MODULE__{} = resources) do
    resources
    |> reduce(@zero, fn v, acc -> Decimal.max(v, acc) end)
    |> Enum.reduce({:cpu, @zero}, fn {res, v}, {_, current_max_v} = acc ->
      if Decimal.compare(current_max_v, v) == :lt,
        do: {res, v},
        else: acc
    end)
  end

  ##################################################################################################
  # Operations
  ##################################################################################################

  @type sum(t, t) ::
          t
  def sum(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:sum, res_a, res_b)

  @type sub(t, t) ::
          t
  def sub(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:sub, res_a, res_b)

  @type div(t, t) ::
          t
  def div(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:div, res_a, res_b)

  def min(%__MODULE__{} = res_a, %__MODULE__{} = res_b) do
    :op_map
    |> dispatch_merge(res_a, res_a, [&Kernel.min/2])
    |> Map.from_struct()
    |> Enum.reject(fn {res, val} -> val == call_resource(res, :initial, []) end)
    |> Map.new()
    |> then(&struct(__MODULE__, &1))
  end

  def equal?(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:equal?, res_a, res_b)

  ##################################################################################################
  # Internal
  ##################################################################################################

  defp dispatch(method, resources, params \\ []) do
    Enum.reduce(@resources, %{}, fn resource, acc ->
      value = Map.fetch!(resources, resource)
      Map.put(acc, resource, call_resource(resource, method, [value] ++ params))
    end)
  end

  defp dispatch_create(method, params \\ []) do
    Enum.reduce(@resources, %{}, fn resource, acc ->
      Map.put(acc, resource, call_resource(resource, method, params))
    end)
    |> from_map()
  end

  defp dispatch_value(method, resources, params \\ []) do
    method
    |> dispatch(resources, params)
    |> from_map()
  end

  defp dispatch_merge(method, res_a, res_b, params \\ []) do
    Map.merge(res_a, Map.take(res_b, @resources), fn resource, v1, v2 ->
      call_resource(resource, method, [v1, v2] ++ params)
    end)
  end

  defp call_resource(resource, method, params) do
    apply(Map.fetch!(@resources_modules, resource), method, [resource | params])
  end
end
