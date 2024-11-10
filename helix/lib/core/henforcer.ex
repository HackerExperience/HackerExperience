defmodule Core.Henforcer do
  @doc """
  TODO
  """
  def henforce_else({true, _} = r, _), do: r
  def henforce_else({false, _, relay}, error), do: {false, error, relay}

  @doc """
  Helper to format the return data in case of success
  """
  def success(relay \\ %{}), do: {true, relay}

  @doc """
  Helper to format the return data in case of failure
  """
  def fail(reason, relay \\ %{}), do: {false, reason, relay}
end
