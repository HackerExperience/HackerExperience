defmodule Game.ConnectionGroup do
  use Core.Schema

  @context :game
  @table :connection_groups

  @group_types [:ssh]

  @schema [
    {:id, ID.ref(:connection_group_id)},
    {:tunnel_id, ID.ref(:tunnel_id)},
    {:group_type, {:enum, values: @group_types}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
