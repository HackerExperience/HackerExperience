defmodule Game.ScannerInstance do
  use Core.Schema

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()

  @context :scanner
  @table :instances

  @instance_types [:connection, :file, :log]

  @schema [
    {:id, ID.Definition.ref(:scanner_instance_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:server_id, ID.Definition.ref(:server_id)},
    {:type, {:enum, values: @instance_types}},
    {:tunnel_id, {ID.Definition.ref(:tunnel_id), nullable: true}},
    {:target_params, {:map, nullable: true}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}}
  ]

  @derived_fields [:id]

  def types, do: @instance_types

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
