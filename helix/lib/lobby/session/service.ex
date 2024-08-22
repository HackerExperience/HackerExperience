defmodule Lobby.Services.Session do
  alias Core.Crypto
  alias Lobby.User

  def create(%User{} = user) do
    ts_now = DateTime.utc_now() |> DateTime.to_unix()

    # TODO
    _session_id = "#{user.id}_#{ts_now}"

    jwt =
      %{
        iat: ts_now,
        exp: ts_now + 86_400 * 7,
        uid: user.external_id
      }
      |> Crypto.JWT.create!()

    # TODO: Actually create session?

    {:ok, jwt}
  end
end
