defmodule Game.ServerMeta do
  use Core.Schema

  @context :server
  @table :meta

  @schema [
    {:id, ID.ref(:server_id)},
    {:resources, {:map, keys: :atom}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
