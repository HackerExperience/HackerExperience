defmodule Game.NetworkConnection do
  use Core.Schema

  @context :game
  @table :network_connections

  @schema [
    {:nip, Core.NIP},
    {:server_id, ID.Definition.ref(:server_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
