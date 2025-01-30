defmodule Game.Server do
  use Core.Schema

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()
  @type idt :: t | id

  @context :game
  @table :servers

  @schema [
    {:id, ID.Definition.ref(:server_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
