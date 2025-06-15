defmodule Game.Process.ResourcesTest do
  use Test.UnitCase, async: true

  alias Game.Process.Resources

  describe "min/2" do
    test "returns the minimum value between two resources" do
      a = %{cpu: 500, ram: 1} |> Resources.from_map()
      b = %{cpu: 2, ram: 900} |> Resources.from_map()

      min = Resources.min(a, b)
      assert min.cpu == Decimal.new(2)
      assert min.ram == Decimal.new(1)
    end
  end

  describe "max/2" do
    test "returns the maximum value between two resources" do
      a = %{cpu: 500, ram: 1} |> Resources.from_map()
      b = %{cpu: 2, ram: 900} |> Resources.from_map()

      max = Resources.max(a, b)
      assert max.cpu == Decimal.new(500)
      assert max.ram == Decimal.new(900)
    end
  end

  describe "resource_per_share" do
    test "returns the expected resources per share" do
      available_resources = %{cpu: 500, ram: 100} |> Resources.from_map()
      shares = %{cpu: 5, ram: 4} |> Resources.from_map()

      per_share = Resources.resource_per_share(available_resources, shares)
      assert_decimal_eq(per_share.cpu, 100)
      assert_decimal_eq(per_share.ram, 25)
    end

    test "defaults to 0 when available resources are negative" do
      available_resources = %{cpu: -100, ram: 10} |> Resources.from_map()
      shares = %{cpu: 5, ram: 2} |> Resources.from_map()

      per_share = Resources.resource_per_share(available_resources, shares)
      assert_decimal_eq(per_share.cpu, 0)
      assert_decimal_eq(per_share.ram, 5)
    end
  end

  describe "overflow?/1" do
    test "returns expected value based on usage, availability and error threshold" do
      [
        {-1, true},
        {-0.1, true},
        {-0.0001, false},
        {0, false},
        {1, false}
      ]
      |> Enum.each(fn {cpu, expected_result} ->
        resources = %{cpu: cpu} |> Resources.from_map()

        case expected_result do
          true ->
            assert {true, [:cpu]} == Resources.overflow?(resources)

          false ->
            refute Resources.overflow?(resources)
        end
      end)
    end

    test "returns a list of all overflowed resources" do
      resources = Resources.from_map(%{cpu: -1, ram: -500, ulk: 0, dlk: 500})
      assert {true, [:ram, :cpu]} = Resources.overflow?(resources)
    end
  end
end
