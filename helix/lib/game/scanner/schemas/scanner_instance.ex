defmodule Game.ScannerInstance do
  use Core.Schema

  alias Game.Scanner.Params.Connection, as: ConnParams
  alias Game.Scanner.Params.File, as: FileParams
  alias Game.Scanner.Params.Log, as: LogParams

  # TODO
  @type t :: term
  @type id :: __MODULE__.ID.t()

  @context :scanner
  @table :instances

  @instance_types [:connection, :file, :log]

  @schema [
    {:id, ID.Definition.ref(:scanner_instance_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:server_id, ID.Definition.ref(:server_id)},
    {:type, {:enum, values: @instance_types}},
    {:tunnel_id, {ID.Definition.ref(:tunnel_id), nullable: true}},
    {:target_params, {:map, load_structs: true, after_read: :format_target_params}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:updated_at, {:datetime_utc, [precision: :millisecond], mod: :updated_at}}
  ]

  @derived_fields [:id]

  def types, do: @instance_types

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end

  def update(%_{} = instance, changes) do
    instance
    |> Schema.update(changes)
  end

  def format_target_params(_, %{target_params: %params_mod{} = target_params}, _),
    do: params_mod.on_db_load(target_params)

  def get_empty_params(:connection), do: %ConnParams{}
  def get_empty_params(:file), do: %FileParams{}
  def get_empty_params(:log), do: %LogParams{}
end
