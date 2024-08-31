defmodule Game.Entity do
  use Feeb.DB.Schema

  @context :game
  @table :entities

  @schema [
    {:id, {:integer, :autoincrement}},
    {:is_player, :boolean},
    {:is_npc, :boolean},
    {:is_clan, :boolean},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
