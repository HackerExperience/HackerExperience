defmodule Game.Process do
  use Core.Schema
  alias Game.Server

  @context :server
  @table :processes

  @process_types [
    :log_edit
  ]

  @schema [
    {:id, ID.ref(:process_id)},
    {:entity_id, ID.ref(:entity_id)},
    {:type, {:enum, values: @process_types}},
    # `data` is the actual process data (e.g. log edit I need the contents of the new log)
    {:data, {:map, keys: :atom, after_read: :hydrate_data}},
    # `registry` includes tgt_log_id, src_file_id etc (same data in ProcessRegistry)
    {:registry, {:map, keys: :atom}},
    {:resources, {:map, after_read: :format_resources}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:server_id, {ID.ref(:server_id), virtual: :get_server_id}}
  ]

  @derived_fields [:id]

  def new(params) do
    # TODO: Validate that `data` is correct (similar go Log schema)

    params
    |> Schema.cast()
    |> Schema.create()
  end

  def update(%_{} = process, changes) do
    process
    |> Schema.update(changes)
  end

  def hydrate_data(%process{} = data, _),
    do: apply(process, :on_db_load, [data])

  def format_resources(resources, _) do
    resources
    |> Map.put(:l_dynamic, Enum.map(resources.l_dynamic, &String.to_existing_atom/1))
  end

  def get_server_id(_, %{shard_id: raw_server_id}), do: Server.ID.from_external(raw_server_id)
end
