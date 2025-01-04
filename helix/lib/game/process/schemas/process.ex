defmodule Game.Process do
  use Core.Schema
  alias Game.Server
  alias __MODULE__

  # TODO
  @type t :: term

  @type priority :: integer

  @context :server
  @table :processes

  @process_types [
    :log_edit
  ]

  @statuses [:awaiting_allocation, :running, :paused]

  @schema [
    {:id, ID.ref(:process_id)},
    {:entity_id, ID.ref(:entity_id)},
    {:type, {:enum, values: @process_types}},
    # `data` is the actual process data (e.g. log edit I need the contents of the new log)
    {:data, {:map, load_structs: true, after_read: :hydrate_data}},
    # `registry` includes tgt_log_id, src_file_id etc (same data in ProcessRegistry)
    {:registry, {:map, load_structs: true}},
    {:status, {:enum, values: @statuses}},
    {:resources, {:map, load_structs: true, after_read: :format_resources}},
    {:priority, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:last_checkpoint_ts, {:integer, nullable: true}},
    {:estimated_completion_ts, {:integer, nullable: true}},
    {:server_id, {ID.ref(:server_id), virtual: true, after_read: :get_server_id}},
    {:next_allocation, {:map, virtual: true}}
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

  def hydrate_data(%process{} = data, _, _),
    do: apply(process, :on_db_load, [data])

  def format_resources(resources, _, _) do
    # TODO: This can be removed if I always insert correctly (and/or normalize the input)
    objective =
      case resources.objective do
        %_{} ->
          resources.objective

        %{} ->
          Process.Resources.from_map(resources.objective)
      end

    resources
    |> Map.put(:l_dynamic, Enum.map(resources.l_dynamic, &String.to_existing_atom/1))
    |> Map.put(:objective, objective)
  end

  def get_server_id(_, _, %{shard_id: raw_server_id}), do: Server.ID.from_external(raw_server_id)

  #

  def get_last_checkpoint_ts(%_{last_checkpoint_ts: nil} = process),
    do: DateTime.to_unix(process.inserted_at, :millisecond)

  def get_last_checkpoint_ts(%_{last_checkpoint_ts: ts}) when is_integer(ts),
    do: ts
end
