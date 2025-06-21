defmodule Core.SpecTest do
  use ExUnit.Case, async: true

  use Norm
  import Core.Spec

  describe "validate_spec/2" do
    test "replaces custom Enum types with proper validation" do
      valid_input = sample_country_input()

      # Works with the country spec
      assert {:ok, valid_input} == validate_spec(valid_input, sample_country_spec())

      # Rejects invalid enum in a specific city (nested spec)
      bad_input_1 =
        put_in(valid_input, [:states, Access.at(1), :cities, Access.at(0), :pollution_level], 6)

      bad_input_2 =
        put_in(valid_input, [:states, Access.at(1), :cities, Access.at(0), :pollution_level], "1")

      bad_input_3 =
        put_in(valid_input, [:states, Access.at(0), :cities, Access.at(0), :security_level], "nope")

      bad_input_4 = Map.put(valid_input, :hemisphere, "sorth")

      assert {:error, [%{input: 6}]} = validate_spec(bad_input_1, sample_country_spec())
      assert {:error, [%{input: "1"}]} = validate_spec(bad_input_2, sample_country_spec())
      assert {:error, [%{input: "nope"}]} = validate_spec(bad_input_3, sample_country_spec())
      assert {:error, [%{input: "sorth"}]} = validate_spec(bad_input_4, sample_country_spec())
    end
  end

  defp sample_country_spec do
    selection(
      schema(%{
        name: binary(),
        hemisphere: enum(["north", "south"]),
        states: coll_of(sample_state_spec())
      }),
      [:name, :states]
    )
  end

  defp sample_state_spec do
    selection(
      schema(%{
        name: binary(),
        cities: coll_of(sample_city_spec())
      }),
      [:name, :cities]
    )
  end

  defp sample_city_spec do
    selection(
      schema(%{
        name: binary(),
        population: integer(),
        security_level: enum(["safe", "moderate", "risky"]),
        pollution_level: enum([1, 2, 3, 4, 5])
      }),
      [:name]
    )
  end

  defp sample_country_input do
    %{
      name: "Brazil",
      hemisphere: "south",
      states: [
        %{
          name: "Rio de Janeiro",
          cities: [
            %{
              name: "Belford Roxo",
              population: 666,
              security_level: "moderate",
              pollution_level: 3
            }
          ]
        },
        %{
          name: "Sao Paulo",
          cities: [
            %{
              name: "Cubatao",
              population: 555,
              security_level: "safe",
              pollution_level: 5
            },
            %{
              name: "Sao Carlos",
              population: 444,
              security_level: "safe",
              pollution_level: 1
            }
          ]
        }
      ]
    }
  end
end
