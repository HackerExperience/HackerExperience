defmodule Lobby.Endpoint.User.LoginTest do
  use Test.WebCase, async: true
  alias HELL.Utils
  alias Core.Crypto
  alias Lobby.Endpoint.User.Register, as: Endpoint

  @path "/user/login"

  setup [:with_lobby_db]

  describe "User.Login request" do
    test "succeeds with correct input", %{shard_id: shard_id} do
      # TODO: Make random
      password = "s3cr3t"

      hashed_password = Core.Crypto.Password.generate_hash!(password)
      user = Setup.lobby_user(password: hashed_password)
      DB.commit()

      # I can login with the correct password
      params = %{email: user.email, password: password}
      assert {:ok, %{data: %{token: jwt}}} = post(@path, params, shard_id: shard_id)

      # The JWT is valid
      assert {true, %{fields: claims}, %{alg: alg}} = Core.Crypto.JWT.verify(jwt)
      assert alg == {:jose_jws_alg_hmac, :HS256}

      # Claims are correct
      assert claims["u_id"] == user.external_id

      # TODO: Properly test iat/exp once I figure out a proper value for them
      assert claims["exp"]
      assert claims["iat"]
    end

    test "fails with incorrect email", %{shard_id: shard_id} do
      # TODO: Make random
      password = "s3cr3t"

      hashed_password = Core.Crypto.Password.generate_hash!(password)
      user = Setup.lobby_user(password: hashed_password)
      DB.commit()

      # I can't login with the wrong email
      params = %{email: "mundialdopalmeiras@doesntexist.com", password: password}
      assert {:error, %{error: reason}} = post(@path, params, shard_id: shard_id)
      assert reason == "bad_password"
    end

    test "fails with incorrect password", %{shard_id: shard_id} do
      # TODO: Make random
      hashed_password = Core.Crypto.Password.generate_hash!("s3cr3t")
      user = Setup.lobby_user(password: hashed_password)
      DB.commit()

      # I can't login with the wrong password
      params = %{email: user.email, password: "wr0ng3r"}
      assert {:error, %{error: reason}} = post(@path, params, shard_id: shard_id)
      assert reason == "bad_password"
    end

    test "fails with missing input", %{shard_id: shard_id} do
      valid_params = valid_raw()

      [
        Map.drop(valid_params, ["password"]),
        Map.drop(valid_params, ["email"])
      ]
      |> Enum.each(fn invalid_params ->
        assert {:error, %{error: reason}} = post(@path, invalid_params, shard_id: shard_id)
        assert reason =~ "missing_or_invalid_input"
      end)
    end
  end

  defp valid_raw do
    # TODO: Make randou
    %{
      email: "foo@bar.com",
      password: "abc123"
    }
    |> Utils.Map.stringify_keys()
  end
end
