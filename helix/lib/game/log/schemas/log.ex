defmodule Game.Log do
  use Core.Schema
  alias Game.Server

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()

  @context :server
  @table :logs

  @log_types [
    :custom,
    :local_login,
    :remote_login_gateway,
    :remote_login_endpoint,
    :connection_proxied
  ]

  @schema [
    {:id, ID.ref(:log_id)},
    {:revision_id, :integer},
    {:type, {:enum, values: @log_types}},
    {:data, {:map, load_structs: true, after_read: :hydrate_data}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:server_id, {ID.ref(:server_id), virtual: true, after_read: :get_server_id}}
  ]

  def new(params) do
    params
    |> validate_data_struct!()
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_, _row, %{shard_id: raw_server_id}), do: Server.ID.from_external(raw_server_id)

  def hydrate_data(data, %{type: type}, _),
    do: data_mod(type).load!(data)

  def data_mod(:local_login), do: __MODULE__.Data.EmptyData
  def data_mod(:custom), do: __MODULE__.Data.EmptyData
  def data_mod(:remote_login_gateway), do: __MODULE__.Data.NIP
  def data_mod(:remote_login_endpoint), do: __MODULE__.Data.NIP
  def data_mod(:connection_proxied), do: __MODULE__.Data.NIPProxy

  defp validate_data_struct!(params) do
    %struct{} = params.data
    true = struct == data_mod(params.type)

    # Transform `data` into a regular map since we've validated its struct matches the log type
    %{params | data: struct.dump!(params.data)}
  end
end
