defmodule Test.Setup.Player do
  use Test.Setup
  alias Game.Player

  def new(opts \\ []) do
    opts
    |> params()
    |> Player.new()
    |> DB.insert!()
  end

  def params(opts \\ []) do
    %{
      external_id: Kw.get(opts, :external_id, Random.uuid())
    }
  end
end
