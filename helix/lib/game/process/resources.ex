defmodule Game.Process.Resources do
  @moduledoc """
  This module is a high-level description of Resources. These Resources are used in processes and
  servers.

  Conceptually, Resources can be thought of as an n-dimensional vector, in which each dimension
  represents an in-game resource (cpu, ram, dlk, ulk, iops, time, ...). These resources are
  independent of one another, and we can perform vector arithmetic operations in them.

  The reason for this data structure becomes obvious when you look at how it's used from inside the
  TOP.Allocator module. We need to perform several vector operations based on the server available
  resources and the process final objective.

  This module is generic in the sense that each resource can have its individual implementation,
  that is, each resource can customize how it applies the vector operations. Currently every
  resource shares the same implementation (Resources.Behaviour.Default.Implementation). For an
  alternative example, Old Helix has the "KV Resource" implementation, in which instead of the
  resource being represented as a Decimal.t(), it is %{key :: term() => value :: Decimal.t()}.
  """

  alias Game.Process
  alias __MODULE__.Behaviour.Default.Implementation, as: DefaultImplementation
  alias __MODULE__.Behaviour.Time.Implementation, as: TimeImplementation

  @zero Decimal.new(0)
  defstruct cpu: @zero, ram: @zero, dlk: @zero, ulk: @zero, time: @zero

  @type t ::
          %__MODULE__{
            cpu: DefaultImplementation.v(),
            ram: DefaultImplementation.v(),
            dlk: DefaultImplementation.v(),
            ulk: DefaultImplementation.v(),
            time: TimeImplementation.v()
          }

  @typedoc "Name that identifies each dimension (resource)."
  @type name ::
          :cpu
          | :ram
          | :dlk
          | :ulk
          | :time

  @typedoc "Acceptable value for each dimension (resource)."
  @type value ::
          DefaultImplementation.v() | TimeImplementation.v()

  @resources [
    :cpu,
    :ram,
    :dlk,
    :ulk,
    :time
  ]

  @resources_modules Enum.map(@resources, fn resource ->
                       resource_module_name =
                         resource
                         |> to_string()
                         |> String.upcase()
                         |> String.replace("TIME", "Time")
                         |> String.to_atom()

                       {resource, Module.concat(__MODULE__, resource_module_name)}
                     end)
                     |> Map.new()

  @doc """
  Builds a Resource.t() from a map. This map may have only some resources, in which case the missing
  ones are built from their corresponding `initial/1` callback.
  """
  @spec from_map(map | [{atom, value}]) ::
          t
  def from_map(resources) do
    %__MODULE__{
      ram: fmt_value(:ram, resources[:ram]),
      cpu: fmt_value(:cpu, resources[:cpu]),
      dlk: fmt_value(:dlk, resources[:dlk]),
      ulk: fmt_value(:ulk, resources[:ulk]),
      time: fmt_value(:time, resources[:time])
    }
  end

  defp fmt_value(res, v),
    do: call_resource(res, :fmt_value, [v])

  ##################################################################################################
  # Callbacks
  ##################################################################################################

  @doc """
  Creates an "initial" Resource, i.e. the full Resource map filled entirely with the corresponding
  initial values for each resource.
  """
  @spec initial() ::
          t
  def initial,
    do: dispatch_create(:initial)

  @doc """
  Creates an "empty" Resource, i.e. the full Resource map filled entirely with the corresponding
  empty (zero) values for each resource.
  """
  @spec empty() ::
          t
  def empty,
    do: dispatch_create(:empty)

  @doc """
  Maps over the Resource, returning a new Resource with the function applied. Similar to Enum.map/2.
  """
  @spec map(t, (value -> value)) ::
          t
  def map(%__MODULE__{} = resources, fun),
    do: dispatch_value(:map, resources, [fun])

  @doc """
  Reduces over the Resource. Similar to Enum.reduce/3.
  """
  @spec reduce(t, acc :: term, (value, acc :: term -> acc :: term)) ::
          t
  def reduce(%__MODULE__{} = resources, acc, fun),
    do: dispatch(:reduce, resources, [acc, fun])

  @doc """
  Creates the static allocation based on the relevant data in the process. Consult each resource
  implementation for more details.
  """
  @spec allocate_static(t) ::
          t
  def allocate_static(process),
    do: dispatch_create(:allocate_static, [process])

  @doc """
  Creates the dynamic allocation based on the relevant data in the process, as well as the total
  number of shares times the dynamic resources per share. Consult each resource implementation for
  more details.
  """
  @spec allocate_dynamic(t, t, Process.t()) ::
          t
  def allocate_dynamic(%__MODULE__{} = shares, %__MODULE__{} = res_per_share, process),
    do: dispatch_merge(:allocate_dynamic, shares, res_per_share, [process])

  @doc """
  Creates a Resource with the number of shares the process should be given for each resource. It
  takes into consideration factors like process priority and whether the process has already reached
  the objective for any given resource. Consult each resource implementation for more details.
  """
  @spec get_shares(Process.t()) ::
          t
  def get_shares(process),
    do: dispatch_create(:get_shares, [process])

  @doc """
  Creates a Resource with the number of "resource units" each share should receive. These values
  represent "resource units per second per share". Consult each resource implementation for more
  details.
  """
  @spec resource_per_share(t, t) ::
          t
  def resource_per_share(%__MODULE__{} = available_resources, %__MODULE__{} = shares),
    do: dispatch_merge(:resource_per_share, available_resources, shares)

  @doc """
  Iterates over the given Resource and checks if any of the values have overflowed, in which case
  it also returns the list of overflowed resources. Consult each resource implementation for more
  details.
  """
  @spec overflow?(t) ::
          {true, [name]}
          | false
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

  @doc """
  Compares the "Processed" Resource with the "Objective" Resource and checks whether it can be
  considered complete. It is complete when all objectives were reached. If any objectives are still
  unfinished, it will return the name of the first resource it found to be incomplete, as well as
  how much is left to complete.
  """
  @spec completed?(processed :: t, objective :: t) ::
          true
          | {false, {name(), remaining :: Decimal.t()}}
  def completed?(%__MODULE__{} = processed, %__MODULE__{} = objective) do
    :completed?
    |> dispatch_merge(processed, objective)
    |> Map.from_struct()
    |> Enum.reduce_while(true, fn {res, res_completed?}, _acc ->
      if res_completed? do
        {:cont, true}
      else
        diff = sub(objective, processed)
        {:halt, {false, {res, get_in(diff, [Access.key!(res)])}}}
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

  @doc """
  Applies the `limits` Resource into the `resources` Resource, based on the logic in the `limitter`
  function below.
  """
  @spec apply_limits(t, t) ::
          t
  def apply_limits(resources, limits) do
    limitter = fn res_value, res_limit ->
      # If the limit is zero, then there is effectively no limit and we should return `res_value`
      if Decimal.eq?(res_limit, @zero) do
        res_value
      else
        # On the other hand, if there is an actual limitation set, return whichever is smaller
        Decimal.min(res_value, res_limit)
      end
    end

    dispatch_merge(:op_map, resources, limits, [limitter])
  end

  @doc """
  Checks whether the resources are equal. Applies an acceptable threshold of 0.0001 for decimals.
  """
  @spec equal?(t, t) ::
          boolean
  def equal?(%__MODULE__{} = res_a, %__MODULE__{} = res_b) do
    :equal?
    |> dispatch_merge(res_a, res_b)
    |> Map.from_struct()
    |> Enum.all?(fn {_, equal?} -> equal? end)
  end

  ##################################################################################################
  # Operations
  ##################################################################################################

  @doc """
  Performs element-wise vector addition of two Resources.
  """
  @spec sum(t, t) ::
          t
  def sum(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:sum, res_a, res_b)

  @doc """
  Performs element-wise vector subtraction of two Resources.
  """
  @spec sub(t, t) ::
          t
  def sub(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:sub, res_a, res_b)

  @doc """
  Performs element-wise vector multiplication of two Resources.
  """
  @spec mul(t, t) ::
          t
  def mul(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:mul, res_a, res_b)

  @doc """
  Performs element-wise vector division of two Resources. Division by zero returns zero.
  """
  @spec div(t, t) ::
          t
  def div(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:div, res_a, res_b)

  @doc """
  Performs element-wise `min/2` operation of two Resources.
  """
  @spec min(t, t) ::
          t
  def min(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:op_map, res_a, res_b, [&Kernel.min/2])

  @doc """
  Performs element-wise `max/2` operation of two Resources.
  """
  @spec max(t, t) ::
          t
  def max(%__MODULE__{} = res_a, %__MODULE__{} = res_b),
    do: dispatch_merge(:op_map, res_a, res_b, [&Kernel.max/2])

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

  defp dispatch_value(method, resources, params) do
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
