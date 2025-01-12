defmodule Game.Server do
  use Core.Schema

  @type id :: __MODULE__.ID.t()

  @context :game
  @table :servers

  @schema [
    {:id, ID.ref(:server_id)},
    {:entity_id, ID.ref(:entity_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
