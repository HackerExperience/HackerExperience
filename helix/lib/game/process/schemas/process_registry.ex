defmodule Game.ProcessRegistry do
  use Core.Schema

  # TODO
  @type t :: term

  # NOTE: I'm adding ProcessRegistry to the Universe shard, but theoretically it could be stored
  # elsewhere, including its own shard or even Redis. It just so happens that I *think* every time
  # we make changes to the ProcessRegistry, we need to make changes to the Universe too.
  @context :game
  @table :processes_registry

  @primary_keys [:server_id, :process_id]

  @schema [
    {:server_id, ID.Definition.ref(:server_id)},
    {:process_id, ID.Definition.ref(:process_id)},
    {:entity_id, ID.Definition.ref(:entity_id)},
    {:src_file_id, {ID.Definition.ref(:file_id), nullable: true}},
    {:tgt_file_id, {ID.Definition.ref(:file_id), nullable: true}},
    {:src_installation_id, {ID.Definition.ref(:installation_id), nullable: true}},
    {:tgt_installation_id, {ID.Definition.ref(:installation_id), nullable: true}},
    {:tgt_log_id, {ID.Definition.ref(:log_id), nullable: true}},
    {:src_tunnel_id, {ID.Definition.ref(:tunnel_id), nullable: true}},
    {:inserted_at, {:datetime_utc, [precision: :millisecond], mod: :inserted_at}}
  ]

  def new(params) do
    params
    |> Schema.cast()
    |> Schema.create()
  end
end
