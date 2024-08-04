defmodule Lobby.User do
  use DBLite.Schema

  @context :lobby
  @table :users

  @schema [
    {:id, {:integer, :autoincrement}},
    {:external_id, :string},
    {:username, :string},
    {:email, :string},
    {:password, :string},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end

  defmodule Validator do
    def validate_username(v) do
      len = String.length(v)
      # TODO: Regex allowlist
      len >= 3 and len <= 20
    end

    def validate_password(v) do
      len = String.length(v)
      len >= 6 and len < 100
    end

    def validate_email(v) do
      len = String.length(v)
      # TODO: Regex allowlist?
      len >= 3 and len < 255 and String.contains?(v, "@")
    end

    def cast_username(v),
      do: v |> String.trim() |> String.downcase()

    def cast_password(v),
      do: String.trim(v)

    def cast_email(v),
      do: v |> String.trim() |> String.downcase()
  end
end
