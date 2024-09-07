defmodule Game.Server do
  use Feeb.DB.Schema

  @context :game
  @table :servers

  @schema [
    {:id, {:integer, :autoincrement}},
    {:entity_id, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
