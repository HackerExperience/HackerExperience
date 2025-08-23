defmodule Game.Installation do
  use Core.Schema
  alias Game.Server

  # TODO
  @type t :: term()
  @type id :: __MODULE__.ID.t()

  @context :server
  @table :installations

  # TODO: Derive from Software schema
  @file_types [
    :cracker,
    :log_editor
  ]

  @schema [
    {:id, ID.Definition.ref(:installation_id)},
    {:file_type, {:enum, values: @file_types}},
    {:file_version, :integer},
    {:file_id, {ID.Definition.ref(:file_id), nullable: true}},
    {:memory_usage, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:server_id, {ID.Definition.ref(:server_id), virtual: true, after_read: :get_server_id}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_, _row, %{shard_id: raw_server_id}), do: Server.ID.new(raw_server_id)
end
