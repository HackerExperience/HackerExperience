defmodule Game.Log do
  use Feeb.DB.Schema

  @context :server
  @table :logs

  @log_types [
    :custom,
    :localhost_logged_in
  ]

  @schema [
    {:id, :integer},
    {:revision_id, :integer},
    {:type, {:enum, values: @log_types}},
    {:data, {:map, keys: :atom}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:server_id, {:integer, virtual: :get_server_id}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_row, %{shard_id: server_id}), do: server_id
end
