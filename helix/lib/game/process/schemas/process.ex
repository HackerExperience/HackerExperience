defmodule Game.Process do
  use Core.Schema
  alias Game.Server
  alias __MODULE__

  @type t :: t(atom())
  @type t(process_type) ::
          %__MODULE__{
            id: id,
            entity_id: term,
            type: process_type,
            data: struct,
            registry: map,
            status: term,
            resources: map,
            priority: integer,
            inserted_at: DateTime.t(),
            last_checkpoint_ts: integer | nil,
            estimated_completion_ts: integer | nil,
            server_id: Server.ID.t(),
            next_allocation: map | :unchanged | :updated | nil,
            __meta__: term,
            __private__: term
          }

  @type id :: __MODULE__.ID.t()

  @type priority :: integer

  @context :server
  @table :processes

  @process_types [
    :file_delete,
    :file_install,
    :file_transfer,
    :installation_uninstall,
    :log_edit,
    # Below are test processes; they do not exist in production
    :noop_cpu,
    :noop_dlk
  ]

  @statuses [:awaiting_allocation, :running, :paused]

  @schema [
    {:id, ID.Definition.ref(:process_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:type, {:enum, values: @process_types}},
    # `data` is the actual process data (e.g. log edit I need the contents of the new log)
    {:data, {:map, load_structs: true, after_read: :hydrate_data}},
    # `registry` includes tgt_log_id, src_file_id etc (same data in ProcessRegistry)
    # TODO: I should reject `nil` values so they don't waste unnecessary space
    {:registry, {:map, load_structs: true}},
    {:status, {:enum, values: @statuses}},
    {:resources, {:map, load_structs: true, after_read: :format_resources}},
    {:priority, :integer},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:last_checkpoint_ts, {:integer, nullable: true}},
    {:estimated_completion_ts, {:integer, nullable: true}},
    {:server_id, {ID.Definition.ref(:server_id), virtual: true, after_read: :get_server_id}},
    {:next_allocation, {:map, virtual: true}}
  ]

  @derived_fields [:id]

  def new(params) do
    params
    |> validate_data_struct!()
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
    resources
    |> Map.put(:dynamic, Enum.map(resources.dynamic, &String.to_existing_atom/1))
  end

  def get_server_id(_, _, %{shard_id: raw_server_id}), do: Server.ID.new(raw_server_id)

  #

  def get_last_checkpoint_ts(%_{last_checkpoint_ts: nil} = process),
    do: DateTime.to_unix(process.inserted_at, :millisecond)

  def get_last_checkpoint_ts(%_{last_checkpoint_ts: ts}) when is_integer(ts),
    do: ts

  #

  def process_mod(:file_delete), do: Process.File.Delete
  def process_mod(:file_install), do: Process.File.Install
  def process_mod(:file_transfer), do: Process.File.Transfer
  def process_mod(:installation_uninstall), do: Process.Installation.Uninstall
  def process_mod(:log_edit), do: Process.Log.Edit
  def process_mod(:noop_cpu), do: Test.Process.NoopCPU
  def process_mod(:noop_dlk), do: Test.Process.NoopDLK

  defp validate_data_struct!(params) do
    # Sanity check: ensure that the process "data" belongs to the expected process type
    %struct{} = params.data
    true = struct == process_mod(params.type) || raise "Bad process data: #{inspect(params)}"
    params
  end
end
