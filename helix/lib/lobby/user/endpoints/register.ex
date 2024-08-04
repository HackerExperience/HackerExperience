defmodule Lobby.Endpoint.User.Register do
  use Norm
  use Webserver.Endpoint
  require Logger

  alias DBLite, as: DB
  alias Core.Crypto
  alias Lobby.User
  alias Lobby.Services, as: Svc

  # TODO: Below is just an example of what a more complex contract would look like
  def input_spec do
    selection(
      schema(%{
        todo_empty_body: spec(is_binary())
      }),
      [:todo_empty_body]
    )
  end

  def output_spec do
    selection(
      schema(%{
        gateways: coll_of(server_spec()),
        endpoints: server_spec()
      }),
      [:gateways]
    )
  end

  def server_spec do
    selection(
      schema(%{
        __openapi_name: "Server",
        nip: spec(is_binary()),
        logs: coll_of(log_spec())
      }),
      [:nip, :logs]
    )
  end

  def log_spec do
    selection(
      schema(%{
        __openapi_name: "Log",
        id: spec(is_binary())
      }),
      [:id]
    )
  end

  def get_params(request, unsafe, _session) do
    with {:ok, username} <- cast(User, :username, unsafe["username"]),
         {:ok, password} <- cast(User, :password, unsafe["password"]),
         {:ok, email} <- cast(User, :email, unsafe["email"]) do
      params = %{username: username, raw_password: password, email: email}
      {:ok, %{request | params: params}}
    else
      {:error, error} ->
        {:error, %{request | response: {400, error}}}
    end
  end

  def get_context(request, params, session) do
    with true <- not Svc.User.email_taken?(params.email) || :email_taken,
         true <- not Svc.User.username_taken?(params.username) || :username_taken,
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
    # DBLite.assert_in_transaction!()

    user_args =
      %{
        external_id: HELL.Random.uuid(),
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
end
