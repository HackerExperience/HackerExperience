defmodule Game.Player do
  use Core.Schema

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()

  @context :game
  @table :players

  @schema [
    # `players.id` is not auto-incrementing. It is defined by `entities.id`.
    {:id, ID.Definition.ref(:player_id)},
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
    def validate_external_id(v) when is_binary(v), do: Renatils.UUID.is_valid?(v)
    def validate_external_id(_), do: false
  end
end
