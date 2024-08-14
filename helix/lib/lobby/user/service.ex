defmodule Lobby.Services.User do
  alias Feeb.DB
  alias Lobby.User

  # Operations

  def create(params) do
    params
    |> User.new()
    |> DB.insert()
  end

  # Queries

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_email: {:one, {:users, :get_by_email}},
      by_username: {:one, {:users, :get_by_username}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end
end
