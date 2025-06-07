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
    {:id, ID.Definition.ref(:file_id)},
    {:type, {:enum, values: @file_types}},
    {:name, :string},
    {:version, :integer},
    {:size, :integer},
    {:path, :string},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}},
    {:server_id, {ID.Definition.ref(:server_id), virtual: true, after_read: :get_server_id}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_, _, %{shard_id: raw_server_id}), do: Server.ID.new(raw_server_id)

  defmodule Validator do
    def validate_name(v) when is_binary(v) do
      len = String.length(v)
      len >= 2 and len <= 15
    end

    def validate_extension(v) when is_binary(v) do
      # TODO: Allow-list
      len = String.length(v)
      len >= 2 and len <= 4
    end

    def validate_version(v) when is_integer(v) do
      v > 0
    end
  end
end
