defmodule Game.Process.Resourceable do
  alias Game.Process.Resources

  def get_resources(resourceable, params) do
    factors = %{todo: :factors}
    args = [factors | params]

    %{
      objective: objective(resourceable, args),
      l_dynamic: l_dynamic(resourceable, args),
      static: static(resourceable, args),
      limit: limit(resourceable, args)
    }
  end

  defp objective(resourceable, args) do
    %{
      cpu: apply(resourceable, :cpu, args),
      ram: apply(resourceable, :ram, args),
      dlk: apply(resourceable, :dlk, args),
      ulk: apply(resourceable, :ulk, args)
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Resources.from_map()
  end

  defp l_dynamic(resourceable, args),
    do: apply(resourceable, :dynamic, args)

  defp static(resourceable, args),
    do: apply(resourceable, :static, args)

  defp limit(resourceable, args),
    do: apply(resourceable, :limit, args) |> Resources.from_map()
end
