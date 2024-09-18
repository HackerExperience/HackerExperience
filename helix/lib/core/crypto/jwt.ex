defmodule Core.Crypto.JWT do
  @alg "HS256"

  # TODO: Add to env
  @jwk %{
         "kty" => "oct",
         "k" => :jose_base64url.encode("todo key goes here move to config")
       }
       |> JOSE.JWK.from_map()

  @jws %{
    "alg" => @alg
  }

  def create!(claims) do
    case create_from_claims(claims) do
      {%{alg: :jose_jws_alg_hmac}, jwt} -> jwt
      err -> raise err
    end
  end

  def create_from_claims(claims) do
    @jwk
    |> JOSE.JWT.sign(@jws, claims)
    |> JOSE.JWS.compact()
  end

  # TODO: Test that `verify` handles exp etc
  # TODO: Pattern match _here_ that the token uses the correct alg and return {:ok, claims} for a
  # simpler API
  def verify(jwt) do
    JOSE.JWT.verify_strict(@jwk, [@alg], jwt)
  end
end
