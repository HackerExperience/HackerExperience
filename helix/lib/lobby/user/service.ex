defmodule Lobby.Services.User do
  # TODO: Rethink API so it becomes deep and narrow instead of shallow and wide

  alias DBLite, as: DB
  alias Lobby.User

  # TODO: Rethink API so it becomes deep and narrow instead of shallow and wide
  def fetch_by_email(email) do
    DB.one({:users, :get_by_email}, [email])
  end

  def email_taken?(email) do
    # TODO: Use custom fields and/or count(*)

    case DB.one({:users, :get_by_email}, [email]) do
      nil -> false
      %{} -> true
    end
  end

  def username_taken?(username) do
    # TODO: Use custom fields and/or count(*)

    case DB.one({:users, :get_by_username}, [username]) do
      nil -> false
      %{} -> true
    end
  end

  def create(params) do
    params
    |> User.new()
    |> DB.insert()
  end
end
