defmodule Game.ProcessRegistry do
  use Core.Schema

  # NOTE: I'm adding ProcessRegistry to the Universe shard, but theoretically it could be stored
  # elsewhere, including its own shard or even Redis. It just so happens that I *think* every time
  # we make changes to the ProcessRegistry, we need to make changes to the Universe too.
  @context :game
  @table :processes_registry

  @schema [
    {:server_id, ID.ref(:server_id)},
    {:process_id, ID.ref(:process_id)},
    {:entity_id, ID.ref(:entity_id)},
    {:tgt_log_id, {ID.ref(:log_id), nullable: true}},
    {:src_file_id, {ID.ref(:file_id), nullable: true}},
    {:tgt_file_id, {ID.ref(:file_id), nullable: true}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
