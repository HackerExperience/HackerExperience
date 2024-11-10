defmodule Test.Assertions do
  @doc """
  Ensure that the returned relay (from the Henforcer) has the given keys (and only them). It did not
  return any extra keys. Useful to make sure relay accumulation is working as expected.
  """
  defmacro assert_relay(relay, keys) do
    quote do
      acc_relay =
        Enum.reduce(unquote(keys), %{}, fn key, acc ->
          # Ensures the key exists on the relay
          assert Map.has_key?(unquote(relay), key)
          Map.put(acc, key, unquote(relay)[key])
        end)

      # The map we built from scratch (while replaying the `keys`) is identical to the initial relay
      assert unquote(relay) == acc_relay
    end
  end
end
