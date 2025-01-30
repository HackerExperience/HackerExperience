defmodule Game.ConnectionGroup do
  use Core.Schema

  @context :game
  @table :connection_groups

  @group_types [:ftp, :ssh]

  @schema [
    {:id, ID.Definition.ref(:connection_group_id)},
    {:tunnel_id, ID.Definition.ref(:tunnel_id)},
    {:type, {:enum, values: @group_types}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
