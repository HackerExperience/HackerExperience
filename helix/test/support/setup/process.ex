defmodule Test.Setup.Process do
  use Test.Setup.Definition
  alias Game.Process.{Executable, Resources}
  alias Game.{Process}
  alias Test.Setup.Process.Spec, as: ProcessSpecSetup

  @doc """
  Opts:
  - type: Defines process type. NoopCPU is picked if unset.
  - spec: Custom opts for the `spec` implementation. Consult docs at `spec/2`. Opts include:
    - params: Process params. If unset, per-process defaults are applied.
    - meta: Process meta. If unset, per-process defaults are applied (new data may be created).
  - objective: Modify the process objective.
  - static: Modify the process static resources. Accepts: %{paused: R}, %{paused: R, running: R}
            or R. Any missing information will default to using the original process static.
  - completed?: When true, the process is created with its `objective` goal already reached.
  - entity_id: Entity who started this process. Defaults to the owner of the server.
  - priority: Customize the process priority.
  """
  def new(server_id, opts \\ []) do
    entity_id =
      if opts[:entity_id] do
        opts[:entity_id]
      else
        Svc.Server.fetch!(by_id: server_id).entity_id
      end

    spec_opts = (opts[:spec] || []) ++ [type: opts[:type]]
    spec = spec(server_id, entity_id, spec_opts)

    # Create the process using Executable
    {:ok, process, _} =
      Executable.execute(spec.module, server_id, entity_id, spec.params, spec.meta)

    process =
      process
      |> maybe_update_resources(opts)
      |> maybe_update_priority(opts)
      |> maybe_mark_as_complete(opts)

    %{
      process: process,
      process_registry: DB.one({:processes_registry, :fetch}, [server_id, process.id]),
      spec: spec
    }
  end

  def new!(server_id, opts \\ []) do
    server_id |> new(opts) |> Map.fetch!(:process)
  end

  @doc """
  Retrieves every possible information from the process.

  Opts:
  - type: Defines process type. If not set, NoopCPU is used
  - params: Overwrites the process params. If nil, a per-process default is applied
  - meta: Overwrites the process meta. If nil, a per-process default is applied
  - <custom>: Each process may define their own custom opts for improved ergonomics
  """
  def spec(server_id, entity_id, opts \\ []) do
    if opts[:type] do
      ProcessSpecSetup.spec(opts[:type], server_id, entity_id, opts)
    else
      ProcessSpecSetup.spec(:noop_cpu, server_id, entity_id, opts)
    end
  end

  defp maybe_update_resources(process, opts) do
    gen_static_value = fn ->
      if custom_static = opts[:static] do
        cond do
          Map.keys(custom_static) == [:running, :paused] ->
            custom_static

          Map.keys(custom_static) == [:paused] ->
            %{
              running: process.resources.static.running,
              paused: custom_static.paused
            }

          true ->
            %{
              running: custom_static,
              paused: process.resources.static.paused
            }
        end
      else
        process.resources.static
      end
    end

    get_resource = fn key ->
      case opts[key] do
        %_{} = resources ->
          resources

        %{} = raw_resources ->
          Resources.from_map(raw_resources)

        nil ->
          Map.fetch!(process.resources, key)
      end
    end

    new_resources =
      process.resources
      |> Map.put(:objective, get_resource.(:objective))
      |> Map.put(:allocated, get_resource.(:allocated))
      |> Map.put(:static, gen_static_value.())
      |> Map.put(:limit, get_resource.(:limit))
      |> Map.put(:dynamic, opts[:dynamic] || process.resources.dynamic)

    update_and_fetch_process!(process, %{resources: new_resources})
  end

  defp maybe_update_priority(process, opts) do
    if custom_priority = opts[:priority] do
      update_and_fetch_process!(process, %{priority: custom_priority})
    else
      process
    end
  end

  def maybe_mark_as_complete(process, opts) do
    if opts[:completed?] || opts[:completed] do
      now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      new_resources =
        process.resources
        |> Map.put(:objective, %{cpu: 1000} |> Resources.from_map())
        |> Map.put(:processed, %{cpu: 1000} |> Resources.from_map())
        |> Map.put(:allocated, %{cpu: 1} |> Resources.from_map())

      # Required changes for a process to be deemed as complete (picked up next by the TOP)
      changes =
        %{
          status: :running,
          resources: new_resources,
          last_checkpoint_ts: now,
          estimated_completion_ts: now
        }

      update_and_fetch_process!(process, changes)
    else
      process
    end
  end

  defp update_and_fetch_process!(process, changes) do
    Core.with_context(:server, process.server_id, :write, fn ->
      process
      |> Process.update(changes)
      |> DB.update!()

      Svc.Process.fetch!(process.server_id, by_id: process.id)
    end)
  end
end
