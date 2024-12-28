defmodule Game.Process.Resources do
  defstruct [:objective, :allocated, :processed]

  @type t ::
          %{
            cpu: number,
            ram: number
          }

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

  def new(objective, allocated, processed) do
    %__MODULE__{
      objective: objective,
      allocated: allocated,
      processed: processed
    }
  end

  ##################################################################################################
  # Callbacks
  ##################################################################################################

  @spec initial() ::
          t
  def initial,
    do: dispatch_create(:initial)

  def allocate_static(process),
    do: dispatch_create(:allocate_static, [process])

  def allocate_dynamic(shares, res_per_share, process),
    do: dispatch_merge(:allocate_dynamic, shares, res_per_share, [process])

  def get_shares(process),
    do: dispatch_create(:get_shares, [process])

  def resource_per_share(available_resources, shares),
    do: dispatch_merge(:resource_per_share, available_resources, shares)

  def overflow?(resources) do
    :overflow?
    |> dispatch_value(resources)
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

  ##################################################################################################
  # Operations
  ##################################################################################################

  @type sum(t, t) ::
          t
  def sum(res_a, res_b),
    do: dispatch_merge(:sum, res_a, res_b)

  @type sub(t, t) ::
          t
  def sub(res_a, res_b),
    do: dispatch_merge(:sub, res_a, res_b)

  def min(res_a, res_b) do
    :op_map
    |> dispatch_merge(res_a, res_a, [&Kernel.min/2])
    |> Enum.reject(fn {res, val} -> val == call_resource(res, :initial, []) end)
    |> Map.new()
  end

  ##################################################################################################
  # Internal
  ##################################################################################################

  defp dispatch_create(method, params \\ []) do
    Enum.reduce(@resources, %{}, fn resource, acc ->
      Map.put(acc, resource, call_resource(resource, method, params))
    end)
  end

  defp dispatch_value(method, resources) do
    Enum.reduce(@resources, %{}, fn resource, acc ->
      value = Map.fetch!(resources, resource)
      Map.put(acc, resource, call_resource(resource, method, [value]))
    end)
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
