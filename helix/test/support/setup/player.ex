defmodule Test.Setup.Player do
  use Test.Setup
  alias Game.Player

  def new(opts \\ []) do
    # TODO: Should I also create the corresponding entity here?

    opts
    |> params()
    |> Player.new()
    |> DB.insert!()
  end

  def params(opts \\ []) do
    %{
      id: Kw.get(opts, :id, Random.int()),
      external_id: Kw.get(opts, :external_id, Random.uuid())
    }
  end
end
