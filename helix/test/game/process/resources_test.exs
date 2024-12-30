defmodule Game.Process.ResourcesTest do
  use ExUnit.Case, async: true

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
end
