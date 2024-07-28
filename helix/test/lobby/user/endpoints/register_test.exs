defmodule Lobby.Endpoint.User.RegisterTest do
  use Test.WebCase, async: true
  alias Core.Crypto
  alias Lobby.Endpoint.User.Register, as: Endpoint

  @path "/user/register"

  setup [:with_lobby_db_readonly]

  describe "User.Register request" do
    test "succeeds with correct input", %{shard_id: shard_id} do
      params = valid_unsafe()
      assert {:ok, %{data: %{id: external_id}}} = post(@path, params, shard_id: shard_id)

      # The user was correctly inserted into the database
      assert [user] = DB.all(Lobby.User)
      assert user.id == 1
      assert user.external_id == external_id
      assert user.username == params["username"]
      assert user.email == params["email"]
      assert user.inserted_at

      # The password is hashed
      refute user.password == params["password"]
      assert Crypto.Password.verify_hash(user.password, params["password"])
    end

    test "fails with missing parameters", %{shard_id: shard_id} do
      valid_params = valid_unsafe()

      [
        {Map.drop(valid_params, ["username"]), "username_missing_input"},
        {Map.drop(valid_params, ["password"]), "password_missing_input"},
        {Map.drop(valid_params, ["email"]), "email_missing_input"}
      ]
      |> Enum.each(fn {invalid_params, expected_error_message} ->
        assert {:error, %{error: reason}} = post(@path, invalid_params, shard_id: shard_id)
        assert reason == expected_error_message
      end)
    end

    test "fails if username is taken", %{shard_id: shard_id} do
      params_1 = valid_unsafe(username: "abc", email: "foo1@bar.com")
      params_2 = valid_unsafe(username: "abc", email: "foo2@bar.com")

      # First request goes through (user is created)
      assert {:ok, _} = post(@path, params_1, shard_id: shard_id)

      # Second request fails
      assert {:error, %{error: reason}} = post(@path, params_2, shard_id: shard_id)
      assert reason == "username_taken"
    end

    test "fails if email is taken", %{shard_id: shard_id} do
      params_1 = valid_unsafe(username: "abc1", email: "foo@bar.com")
      params_2 = valid_unsafe(username: "abc2", email: "foo@bar.com")

      # First request goes through (user is created)
      assert {:ok, _} = post(@path, params_1, shard_id: shard_id)

      # Second request fails
      assert {:error, %{error: reason}} = post(@path, params_2, shard_id: shard_id)
      assert reason == "email_taken"
    end
  end

  describe "get_context/3" do
    test "proceeds on valid context", %{session: session} do
      params = valid_params()
      assert {:ok, %{context: context}} = Endpoint.get_context(gen_req(), params, session)

      # There is a hashed password in the context
      assert Map.has_key?(context, :hashed_password)

      # Which is definitely not the same as the original password
      refute context.hashed_password == params.raw_password

      # We can actually verify the original password by hashing it
      assert Crypto.Password.verify_hash(context.hashed_password, params.raw_password)
    end
  end

  defp valid_unsafe(opts \\ []) do
    # TODO: Make random
    %{
      username: Keyword.get(opts, :username, "abc"),
      password: Keyword.get(opts, :password, "abc123"),
      email: Keyword.get(opts, :email, "foo@bar.com")
    }
    |> Utils.Map.stringify_keys()
  end

  defp valid_params(opts \\ []) do
    # TODO: Make random
    %{
      username: Keyword.get(opts, :username, "abc"),
      raw_password: Keyword.get(opts, :password, "abc123"),
      email: Keyword.get(opts, :email, "foo@bar.com")
    }
  end
end
