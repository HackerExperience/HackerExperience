defmodule Game.FileVisibility do
  use Core.Schema
  alias Game.Entity

  @type t :: term()

  @context :player
  @table :file_visibilities

  @schema [
    {:server_id, ID.Definition.ref(:server_id)},
    {:file_id, ID.Definition.ref(:file_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:entity_id, {ID.Definition.ref(:entity_id), virtual: true, after_read: :get_entity_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_entity_id(_, _, %{shard_id: raw_entity_id}), do: Entity.ID.new(raw_entity_id)
end
