defmodule Game.Installation do
  use Core.Schema

  @context :server
  @table :installations

  @file_types [
    :log_editor
  ]

  @schema [
    {:id, ID.ref(:installation_id)},
    {:file_type, {:enum, values: @file_types}},
    {:file_version, :integer},
    {:file_id, {ID.ref(:file_id), nullable: true}},
    {:memory_usage, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
