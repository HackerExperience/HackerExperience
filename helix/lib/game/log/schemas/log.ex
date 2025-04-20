defmodule Game.Log do
  use Core.Schema
  alias Game.Server
  alias __MODULE__.Data, as: LogData

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()

  @context :server
  @table :logs

  @log_types [
    :custom,
    :file_deleted,
    :file_downloaded,
    :file_uploaded,
    :server_login,
    :connection_proxied
  ]

  # The log direction is used when rendering the log text, since it affects the final result. Imagine
  # the scenario where a file is deleted. Here are the possible options:
  # - self:    localhost deleted file [foo.bar (1.0)]
  # - to_ap:   localhost deleted file [foo.bar (1.0)] on [1.2.3.4]
  # - from_en: [5.6.7.8] deleted file [foo.bar (1.0)] on localhost
  # Even though all log entries above share the same type (:file_deleted), each one is rendered
  # slightly differently based on the direction. `hop` is used exclusively for `connection_proxied`.
  @log_directions [
    :self,
    :to_ap,
    :from_en,
    :hop
  ]

  @schema [
    {:id, ID.Definition.ref(:log_id)},
    {:revision_id, ID.Definition.ref(:log_revision_id)},
    {:type, {:enum, values: @log_types}},
    {:direction, {:enum, values: @log_directions}},
    {:data, {:map, load_structs: true, after_read: :hydrate_data}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:deleted_at, {:datetime_utc, nullable: true, precision: :millisecond}},
    {:deleted_by, {ID.Definition.ref(:entity_id), nullable: true}},
    {:server_id, {ID.Definition.ref(:server_id), virtual: true, after_read: :get_server_id}},
    {:is_deleted, {:boolean, virtual: true, after_read: :get_is_deleted}}
  ]

  def new(params) do
    params
    |> validate_data_struct!()
    |> Schema.cast()
    |> Schema.create()
  end

  def get_server_id(_, _row, %{shard_id: raw_server_id}), do: Server.ID.new(raw_server_id)

  def get_is_deleted(_, %{deleted_at: nil}, _), do: false
  def get_is_deleted(_, %{deleted_at: %DateTime{}}, _), do: true

  def hydrate_data(data, %{type: type, direction: direction}, _),
    do: data_mod({type, direction}).load!(data)

  def data_mod({:custom, :self}), do: LogData.EmptyData
  def data_mod({:file_deleted, :self}), do: LogData.LocalFile
  def data_mod({:file_deleted, dir}) when dir in [:to_ap, :from_en], do: LogData.RemoteFile
  def data_mod({:file_downloaded, dir}) when dir in [:to_ap, :from_en], do: LogData.RemoteFile
  def data_mod({:file_uploaded, dir}) when dir in [:to_ap, :from_en], do: LogData.RemoteFile
  def data_mod({:server_login, :self}), do: LogData.EmptyData
  def data_mod({:server_login, dir}) when dir in [:to_ap, :from_en], do: LogData.NIP
  def data_mod({:connection_proxied, :hop}), do: LogData.NIPProxy

  defp validate_data_struct!(params) do
    %struct{} = params.data
    true = struct == data_mod({params.type, params.direction})

    # Transform `data` into a regular map since we've validated its struct matches the log type
    %{params | data: struct.dump!(params.data)}
  end
end
