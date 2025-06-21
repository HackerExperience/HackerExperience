defmodule Test.Utils.Process do
  use Test.Setup.Definition

  alias Game.Process.TOP
  alias Game.{Process, Server, Tunnel}
  alias Game.Process.Processable

  def get_all_process_registries do
    Core.with_context(:universe, :read, fn ->
      Svc.Process.list_registry(query: :all)
    end)
  end

  def get_all_processes(%Server.ID{} = server_id) do
    Svc.Process.list(server_id, query: :all)
  end

  def execute(server_id_or_spec, optional_opts \\ [])

  def execute(%Server.ID{} = server_id, opts) do
    server_id
    |> S.process_spec(opts)
    |> execute()
  end

  def execute(spec, _) when is_map(spec),
    do: Svc.TOP.execute(spec.module, spec.server_id, spec.entity_id, spec.params, spec.meta)

  def mark_as_complete(%Process{} = process) do
    S.Process.maybe_mark_as_complete(process, completed: true)
  end

  def simulate_process_completion(%Process{} = process) do
    if not TOP.Scheduler.is_completed?(process) do
      mark_as_complete(process)
    end

    universe = Elixir.Process.get(:helix_universe)
    shard_id = Elixir.Process.get(:helix_universe_shard_id)

    # Just start the TOP. Since `process` has reached its objectives, on the initial scheduling the
    # TOP will complete the process accordingly.
    TOP.on_boot({universe, shard_id})
  end

  def processable_on_complete(%Process{} = process),
    do: Processable.on_complete(process)

  def start_top(%Server.ID{} = server_id, opts \\ []) do
    {:ok, pid} = TOP.Registry.fetch_or_create(server_id)

    if opts[:wait_for_recalcado] do
      Test.Event.wait_events_on_server!(server_id, :top_recalcado)
    end

    pid
  end

  @doc """
  Adds the given Tunnel to the Process as `src_tunnel_id`.

  PS: If you need to persist the change in the database, then extend the function to do so.
  """
  def add_tunnel_to_process(%Process{registry: registry} = process, %Tunnel.ID{} = tunnel_id) do
    %{process | registry: %{registry | src_tunnel_id: tunnel_id}}
  end
end
