defmodule Lobby.Endpoint.User.Login do
  use Norm
  use Webserver.Endpoint
  require Logger

  alias DBLite, as: DB
  alias Lobby.User
  alias Lobby.Services, as: Svc
  alias Core.Crypto

  def input_spec do
    selection(
      schema(%{
        password: spec(is_binary() and (&cast_and_validate(&1, :password))),
        email: spec(is_binary())
      }),
      [:password, :email]
    )
  end

  def output_spec() do
    selection(
      schema(%{
        token: spec(is_binary())
      }),
      [:token]
    )
  end

  def get_params(request, unsafe, _session) do
    with {:ok, password} <- cast(User, :password, unsafe["password"]),
         {:ok, email} <- cast(User, :email, unsafe["email"]) do
      params = %{raw_password: password, email: email}
      {:ok, %{request | params: params}}
    else
      {:error, error} ->
        {:error, %{request | response: {400, error}}}
    end
  end

  def get_context(request, %{email: email, raw_password: raw_pwd}, session) do
    with %User{} = user <- Svc.User.fetch_by_email(email) || :nxuser,
         :ok = DB.commit(),
         true <- Crypto.Password.verify_hash(user.password, raw_pwd) || :bad_password do
      # TODO: NOTE: shard_id must not be hardcoded because tests
      DB.begin(:lobby, 1, :read)
      {:ok, %{request | context: %{user: user}}}
    else
      :nxuser ->
        # TODO
        # # Dummy hashing to avoid leaking (via timing attack) that the given email is used
        # # in the system. This is also why we return `password_mismatch` here.
        # Crypto.Password.verify_hash(Crypto.Password.dummy_hash(), raw_pwd)
        {:error, %{request | response: {422, "bad_password"}}}

      :bad_password ->
        {:error, %{request | response: {422, "bad_password"}}}
    end
  end

  def handle_request(request, _params, %{user: user}, _session) do
    # DB.assert_in_transaction!()

    case Svc.Session.create(user) do
      {:ok, jwt} ->
        {:ok, %{request | result: %{jwt: jwt}}}

      {:error, reason} ->
        Logger.error("Failed to create session: #{inspect(reason)}")
        {:error, %{request | response: {500, "error_creating_session"}}}
    end
  end

  def render_response(request, %{jwt: jwt}, _session) do
    {:ok, %{request | response: {200, %{token: jwt}}}}
  end

  # Private

  defp cast_and_validate(value, :password),
    do: value |> cast(:password) |> User.Validator.validate_password()

  defp cast(value, :password), do: User.Validator.cast_password(value)
end
