defmodule Game.Connection do
  use Core.Schema

  @context :game
  @table :connections

  @connection_types [
    :ftp,
    :proxy,
    :ssh
  ]

  @schema [
    {:id, ID.Definition.ref(:connection_id)},
    {:nip, NIP},
    {:from_nip, {NIP, nullable: true}},
    {:to_nip, {NIP, nullable: true}},
    {:type, {:enum, values: @connection_types}},
    {:group_id, ID.Definition.ref(:connection_group_id)},
    {:tunnel_id, ID.Definition.ref(:tunnel_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> Schema.cast(:all)
    # TODO: Validate that one of (from_nip, to_nip) is set
    |> Schema.create()
  end
end
