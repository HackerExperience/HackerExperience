defmodule Game.LogVisibility do
  use Core.Schema

  @context :player
  @table :log_visibilities

  @schema [
    {:server_id, ID.ref(:server_id)},
    {:log_id, ID.ref(:log_id)},
    {:revision_id, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:entity_id, {ID.ref(:entity_id), virtual: :get_entity_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_entity_id(_, %{shard_id: entity_id}), do: entity_id
end
