defmodule Game.LogVisibility do
  use Feeb.DB.Schema

  @context :player
  @table :log_visibilities

  @schema [
    {:server_id, :integer},
    {:log_id, :integer},
    {:revision_id, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:entity_id, {:integer, virtual: :get_entity_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_entity_id(_, %{shard_id: entity_id}), do: entity_id
end
