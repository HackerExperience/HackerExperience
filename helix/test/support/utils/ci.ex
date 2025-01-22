defmodule Test.Utils.CI do
  @doc """
  CI is slow. Some tests may need additional time for asynchronous stuff to get processed. Ideally
  this should be avoided, but some times it is necessary...
  """
  def sleep_on_ci(duration) when is_integer(duration) do
    if is_ci?(), do: IO.puts("Sleeping on CI")
    if is_ci?(), do: :timer.sleep(duration)
  end

  @doc """
  Checks whether we are running inside CI. We can expectd the `IS_CI` envvar to always be available.
  """
  def is_ci? do
    System.get_env("IS_CI", "false") == "true"
  end
end
