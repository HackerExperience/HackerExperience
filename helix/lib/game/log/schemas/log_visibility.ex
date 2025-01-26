defmodule Game.LogVisibility do
  use Core.Schema
  alias Game.Entity

  @type t :: term

  @context :player
  @table :log_visibilities

  @schema [
    {:server_id, ID.ref(:server_id)},
    {:log_id, ID.ref(:log_id)},
    {:revision_id, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:entity_id, {ID.ref(:entity_id), virtual: true, after_read: :get_entity_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_entity_id(_, _, %{shard_id: raw_entity_id}), do: Entity.ID.from_external(raw_entity_id)
end
