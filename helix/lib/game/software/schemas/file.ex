defmodule Game.File do
  use Core.Schema

  # TODO
  @type t :: term()
  @type id :: __MODULE__.ID.t()

  @context :server
  @table :files

  @file_types [
    :log_editor
  ]

  @schema [
    {:id, ID.ref(:file_id)},
    {:type, {:enum, values: @file_types}},
    {:version, :integer},
    {:size, :integer},
    {:path, :string},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
