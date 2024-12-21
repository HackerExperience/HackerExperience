defmodule Game.TunnelLink do
  use Core.Schema

  @context :game
  @table :tunnel_links

  @schema [
    {:tunnel_id, ID.ref(:tunnel_id)},
    {:idx, :integer},
    {:nip, NIP},
    {:server_id, ID.ref(:server_id)},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
