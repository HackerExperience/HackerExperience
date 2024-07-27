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
    def password(v, opts) when is_binary(v) do
      v = if opts[:cast], do: String.trim(v), else: v
      len = String.length(v)

      with true <- len < 100,
           true <- len >= 6 do
        {:ok, v}
      else
        _ -> :error
      end
    end

    def username(v, opts) when is_binary(v) do
      v = if opts[:cast], do: cast_username(v), else: v
      len = String.length(v)

      # TODO: Regex allowlist
      with true <- len <= 20,
           true <- len >= 3 do
        {:ok, v}
      else
        _ -> :error
      end
    end

    def email(v, opts) when is_binary(v) do
      v = if opts[:cast], do: cast_email(v), else: v

      # TODO: Regex
      with true <- String.length(v) < 255,
           true <- String.length(v) >= 3,
           true <- String.contains?(v, "@") do
        {:ok, v}
      else
        _ -> :error
      end
    end

    defp cast_username(v) do
      # TODO: Generic cast
      v
      |> String.trim()
      |> String.downcase()
    end

    defp cast_email(v) do
      v
      |> String.trim()
      |> String.downcase()
    end
  end
end
