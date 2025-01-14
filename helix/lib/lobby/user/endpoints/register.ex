defmodule Lobby.Endpoint.User.Register do
  @behaviour Webserver.Endpoint.Behaviour

  use Norm
  import Core.Spec
  require Logger

  alias Feeb.DB
  alias Core.Crypto
  alias Lobby.User
  alias Lobby.Services, as: Svc

  def input_spec do
    selection(
      schema(%{
        "username" => spec(is_binary() and (&cast_and_validate(&1, :username))),
        "password" => spec(is_binary() and (&cast_and_validate(&1, :password))),
        "email" => spec(is_binary() and (&cast_and_validate(&1, :email)))
      }),
      ["username", "password", "email"]
    )
  end

  def output_spec(200) do
    selection(
      schema(%{
        # TODO: uuid
        id: binary()
      }),
      [:id]
    )
  end

  def get_params(request, parsed, _session) do
    username = User.Validator.cast_username(parsed.username)
    password = User.Validator.cast_password(parsed.password)
    email = User.Validator.cast_email(parsed.email)

    params = %{username: username, raw_password: password, email: email}
    {:ok, %{request | params: params}}
  end

  def get_context(request, params, session) do
    with true <- not email_taken?(params.email) || :email_taken,
         true <- not username_taken?(params.username) || :username_taken,
         # Release connection so it does not block while password is being hashed
         :ok = DB.commit(),
         hashed_password = Crypto.Password.generate_hash!(params.raw_password) do
      DB.begin(:lobby, session.shard_id, :write)
      {:ok, %{request | context: %{hashed_password: hashed_password}}}
    else
      :email_taken ->
        {:error, %{request | response: {400, "email_taken"}}}

      :username_taken ->
        {:error, %{request | response: {400, "username_taken"}}}
    end
  end

  def handle_request(request, params, context, _session) do
    # TODO
    # Feeb.DB.assert_in_transaction!()

    user_args =
      %{
        external_id: Renatils.Random.uuid(),
        username: params.username,
        email: params.email,
        password: context.hashed_password
      }

    with {:ok, user} <- Svc.User.create(user_args) do
      {:ok, %{request | result: %{user: user}}}
    else
      {:error, reason} ->
        Logger.error("Unable to create user: #{inspect(reason)}")
        {:error, %{request | response: {400, "error_creating_user"}}}
    end
  end

  def render_response(request, %{user: %{external_id: external_id}}, _session) do
    {:ok, %{request | response: {200, %{id: external_id}}}}
  end

  # Private

  defp cast_and_validate(value, :username),
    do: value |> User.Validator.cast_username() |> User.Validator.validate_username()

  defp cast_and_validate(value, :password),
    do: value |> User.Validator.cast_password() |> User.Validator.validate_password()

  defp cast_and_validate(value, :email),
    do: value |> User.Validator.cast_email() |> User.Validator.validate_email()

  defp email_taken?(email) do
    case Svc.User.fetch(by_email: email) do
      nil -> false
      %{} -> true
    end
  end

  defp username_taken?(username) do
    case Svc.User.fetch(by_username: username) do
      nil -> false
      %{} -> true
    end
  end
end
