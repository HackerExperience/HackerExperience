defmodule Game.Player do
  use Feeb.DB.Schema

  @context :game
  @table :players

  @schema [
    # `players.id` is not auto-incrementing. It is defined by `entities.id`.
    {:id, :integer},
    {:external_id, :uuid},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.validate_fields([:external_id])
    |> Schema.create()
  end

  defmodule Validator do
    def validate_external_id(v) when is_binary(v), do: Utils.UUID.is_valid?(v)
    def validate_external_id(_), do: false
  end
end
