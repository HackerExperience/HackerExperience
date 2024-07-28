defmodule Test.Setup.Lobby.User do
  use Test.Setup
  alias Lobby.User

  def new(opts \\ []) do
    opts
    |> params
    |> User.new()
    |> DB.insert!()
  end

  def params(opts \\ []) do
    # TODO: Make random
    %{
      external_id: Kw.get(opts, :external_id, Random.uuid()),
      email: Kw.get(opts, :email, "foo@bar.com"),
      username: Kw.get(opts, :username, "foobar"),
      password: Kw.get(opts, :password, "hashed_password")
    }
  end
end
