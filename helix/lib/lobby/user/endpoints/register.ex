defmodule Lobby.Endpoint.User.Register do
  use Webserver.Endpoint
  require Logger

  # alias Core.Crypto
  # alias Lobby.User
  # alias Lobby.Services, as: Svc
  # alias Lobby.Events.UserCreated, as: UserCreatedEvent

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
    # DB.assert_in_transaction!()

    company_args = %{
      global_id: Utils.Random.uuid(),
      name: "Minha Empresa"
    }

    user_args = %{
      global_id: Utils.Random.uuid(),
      email: params.email,
      password: context.hashed_password
    }

    with {:ok, company} <- Svc.Company.create(company_args),
         user_args = Map.put(user_args, :company_id, company.id),
         {:ok, user} <- Svc.User.create(user_args) do
      result = %{user: user, company: company}
      events = [UserCreatedEvent.new(user)]
      {:ok, %{request | result: result, events: events}}
    else
      {:error, reason} ->
        Logger.error(reason)
        {:error, %{request | response: {400, "error_creating_user"}}}
    end
  end

  def render_response(request, %{user: %{global_id: global_id}}, _session) do
    {:ok, %{request | response: {200, %{id: global_id}}}}
  end
end