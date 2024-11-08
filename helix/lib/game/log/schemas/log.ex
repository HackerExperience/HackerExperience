defmodule Game.Log do
  use Core.Schema

  @context :server
  @table :logs

  @log_types [
    :custom,
    :localhost_logged_in
  ]

  @schema [
    {:id, ID.ref(:log_id)},
    {:revision_id, :integer},
    {:type, {:enum, values: @log_types}},
    {:data, {:map, keys: :atom}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:server_id, {ID.ref(:server_id), virtual: :get_server_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_row, %{shard_id: raw_server_id}), do: raw_server_id
end
