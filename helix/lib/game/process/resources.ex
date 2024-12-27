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

  def initial,
    do: dispatch_create(:initial)

  @type sum(t, t) ::
          t
  def sum(res_a, res_b) do
    dispatch_merge(:sum, res_a, res_b)
  end

  defp dispatch_create(method, params \\ []) do
    Enum.reduce(@resources, %{}, fn resource, acc ->
      result = call_resource(resource, method, params)

      Map.put(acc, resource, result)
    end)
  end

  defp dispatch_merge(method, res_a, res_b, params \\ []) do
    Map.merge(res_a, Map.take(res_b, @resources), fn resource, v1, v2 ->
      call_resource(resource, method, [v1, v2] ++ params)
    end)
  end

  defp call_resource(resource, method, params) do
    apply(Map.fetch!(@resources_modules, resource), method, params)
  end
end
