defmodule Game.Process.Resourceable do
  def get_resources(resourceable, params) do
    factors = %{to: :do}
    args = [factors, params]

    %{
      objective: objective(resourceable, args),
      l_dynamic: l_dynamic(resourceable, args)
    }
  end

  defp objective(resourceable, args) do
    %{
      cpu: apply(resourceable, :cpu, args),
      ram: apply(resourceable, :ram, args)
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp l_dynamic(resourceable, args),
    do: apply(resourceable, :dynamic, args)
end
