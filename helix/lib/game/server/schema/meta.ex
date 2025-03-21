defmodule Game.ServerMeta do
  use Core.Schema

  @context :server
  @table :meta

  @schema [
    {:id, ID.Definition.ref(:server_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:resources, {:map, load_structs: true}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def update(%_{} = meta, changes) do
    meta
    |> Schema.update(changes)
  end
end
