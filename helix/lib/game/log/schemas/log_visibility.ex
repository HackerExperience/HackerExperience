defmodule Game.LogVisibility do
  use Core.Schema
  alias Game.Entity

  @type t :: term

  @context :player
  @table :log_visibilities

  @visibility_sources [
    :self,
    :edit
  ]

  @primary_keys [:server_id, :log_id, :revision_id]

  @schema [
    {:server_id, ID.Definition.ref(:server_id)},
    {:log_id, ID.Definition.ref(:log_id)},
    {:revision_id, ID.Definition.ref(:log_revision_id)},
    {:source, {:enum, values: @visibility_sources}},
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
