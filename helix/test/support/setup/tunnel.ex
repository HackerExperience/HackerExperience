defmodule Test.Setup.Tunnel do
  use Test.Setup.Definition
  alias Game.Tunnel

  def new(opts \\ []) do
    tunnel =
      opts
      |> params()
      |> Tunnel.new()
      |> DB.insert!()

    %{tunnel: tunnel}
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:tunnel)

  def params(opts \\ []) do
    %{
      source_nip: Kw.get(opts, :source_nip, "0@1.2.3.4"),
      target_nip: Kw.get(opts, :target_nip, "0@4.3.2.1"),
      access: Kw.get(opts, :access, :ssh),
      status: Kw.get(opts, :status, :open)
    }
  end
end
