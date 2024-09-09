defmodule Test.Utils.Token do
  use Test.Setup.Definition
  alias Core.Crypto

  def generate(opts \\ []) do
    ts_now = Utils.DateTime.ts_now()

    %{
      uid: Kw.get(opts, :uid, Random.uuid()),
      iat: Kw.get(opts, :iat, ts_now),
      exp: Kw.get(opts, :exp, ts_now + 86_400 * 7)
    }
    |> Crypto.JWT.create!()
  end
end
