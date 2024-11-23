defmodule Core.NIPTest do
  use Test.UnitCase, async: true
  alias Core.NIP

  describe "parse_external/1" do
    test "returns nip when input is valid" do
      [
        {0, "1.1.1.1"},
        {509_834, "93.28.0.128"},
        {Random.int(), Random.ip()}
      ]
      |> Enum.each(fn {input_network_id, input_ip} ->
        assert {:ok, %NIP{network_id: input_network_id, ip: input_ip}} ==
                 NIP.parse_external("#{input_network_id}@#{input_ip}")
      end)
    end

    test "returns error when input is invalid" do
      [
        {"1.1.1.1", :invalid_nip},
        {"@", {:invalid_network_id, ""}},
        {"z@1.1.1.1", {:invalid_network_id, "z"}},
        {"1@", {:invalid_ip, ""}},
        {"z@", {:invalid_network_id, "z"}},
        {"1@1.1.1.1@1", :invalid_nip},
        {"1@500.400.300.200", {:invalid_ip, "500.400.300.200"}}
      ]
      |> Enum.each(fn {input, expected_reason} ->
        assert {:error, expected_reason} == NIP.parse_external(input)
      end)
    end
  end
end
