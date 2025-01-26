defmodule Game.File do
  use Core.Schema
  alias Game.Server

  # TODO
  @type t :: term()
  @type id :: __MODULE__.ID.t()
  @type idt :: t | id

  @context :server
  @table :files

  @file_types [
    :log_editor
  ]

  @schema [
    {:id, ID.ref(:file_id)},
    {:type, {:enum, values: @file_types}},
    {:name, :string},
    {:version, :integer},
    {:size, :integer},
    {:path, :string},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}},
    {:server_id, {ID.ref(:server_id), virtual: true, after_read: :get_server_id}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_, _, %{shard_id: raw_server_id}), do: Server.ID.from_external(raw_server_id)
end
