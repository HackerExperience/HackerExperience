defmodule Game.ExternalID do
  use Core.Schema

  @type t :: term
  @type id :: String.t()

  @context :player
  @table :external_ids

  @object_types [
    :file_id,
    :installation_id,
    :log_id,
    :log_revision_id,
    :process_id,
    :server_id,
    :tunnel_id
  ]

  @primary_keys [:external_id]

  @schema [
    {:external_id, :string},
    {:object_id, :integer},
    {:object_type, {:enum, values: @object_types}},
    {:domain_id, {:integer, nullable: true}},
    {:subdomain_id, {:integer, nullable: true}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
