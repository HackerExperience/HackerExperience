defmodule Core.Crypto.Password.Argon2 do
  use Rustler,
    otp_app: :helix,
    crate: "argon2"

  def hash(_pepper, _pwd), do: error()
  def verify(_pepper, _pwd, _hash), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
