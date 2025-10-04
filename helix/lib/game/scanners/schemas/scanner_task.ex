defmodule Game.ScannerTask do
  use Core.Schema

  # TODO
  @type t :: term
  @type id :: String.t()

  @context :scanner
  @table :tasks

  @instance_types_fn fn ->
    # `ScannerInstance.types` without the transitive compile-time dependency
    apply(:"Elixir.Game.ScannerInstance", :types, [])
  end

  @schema [
    {:instance_id, ID.Definition.ref(:scanner_instance_id)},
    {:run_id, :string},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:server_id, ID.Definition.ref(:server_id)},
    {:type, {:enum, values: @instance_types_fn}},
    # A nullable target means the scanner is sleeping
    {:target_id, {:integer, nullable: true}},
    {:scheduled_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}},
    {:completion_date, :integer},
    {:next_backoff, {:integer, nullable: true}},
    {:failed_attempts, {:integer, default: 0}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
