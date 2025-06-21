defmodule Core.Spec do
  use Docp
  import Norm

  def validate_spec(input, spec) do
    spec = replace_spec_enums(spec)
    Norm.conform(input, spec)
  end

  def validate_spec!(input, spec) do
    {:ok, v} = validate_spec(input, spec)
    v
  end

  def external_id, do: spec(is_binary())
  def nip, do: spec(is_binary())
  def binary, do: spec(is_binary())
  def integer, do: spec(is_integer())
  def boolean, do: spec(is_boolean())
  def map, do: spec(is_map())

  def enum(values) when is_list(values) do
    {:enum, get_enum_type(values), values}
  end

  @docp """
  Recurse through the spec until (if) it finds an Enum, and then replace it with proper validation.
  """
  defp replace_spec_enums(%Norm.Core.Selection{schema: schema} = outer_spec) do
    new_specs =
      Enum.map(schema.specs, fn {name, spec} ->
        {name, replace_spec_enums(spec)}
      end)
      |> Map.new()

    put_in(outer_spec, [Access.key!(:schema), Access.key!(:specs)], new_specs)
  end

  defp replace_spec_enums({:enum, _, values}), do: spec(fn v -> v in values end)
  defp replace_spec_enums(%Norm.Core.Spec{predicate: _} = predicate), do: predicate

  defp replace_spec_enums(%Norm.Core.Collection{spec: inner_spec} = collection),
    do: Map.put(collection, :spec, replace_spec_enums(inner_spec))

  defp replace_spec_enums(v), do: v

  defp get_enum_type([v | _]) when is_binary(v), do: :string
  defp get_enum_type([v | _]) when is_atom(v), do: :string
  defp get_enum_type([v | _]) when is_integer(v), do: :integer
end
