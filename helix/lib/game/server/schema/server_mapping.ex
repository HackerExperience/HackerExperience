defmodule Game.ServerMapping do
  use Feeb.DB.Schema

  @context :game
  @table :server_mappings

  @schema [
    {:server_id, {:integer, :autoincrement}},
    {:entity_id, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:server_id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
