defmodule Game.Entity do
  use Feeb.DB.Schema

  @context :game
  @table :entities

  @entity_types [:player, :npc, :clan]

  @schema [
    {:id, {:integer, :autoincrement}},
    {:type, {:enum, values: @entity_types}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
