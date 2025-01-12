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
end
