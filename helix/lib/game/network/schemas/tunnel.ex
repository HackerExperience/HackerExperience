defmodule Game.Tunnel do
  use Core.Schema

  @type t :: term
  @type id :: __MODULE__.ID.t()
  @type idt :: t | id

  @context :game
  @table :tunnels

  @access_types [:ssh]
  @status_types [:open, :closed]

  @schema [
    {:id, ID.ref(:tunnel_id)},
    {:source_nip, NIP},
    {:target_nip, NIP},
    {:access, {:enum, values: @access_types}},
    {:status, {:enum, values: @status_types}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}}
  ]

  @derived_fields [:id]

  # TODO: Should I have an API to create multiple at once?
  def new(params) do
    params
    |> Schema.cast(:all)
    # Below is an idea of what the API could look like. Nothing set in stone yet.
    # |> validate_fields([:access, :status])
    # |> validate_context([&no_cyclic_tunnel/1])
    |> Schema.create()
  end
end
