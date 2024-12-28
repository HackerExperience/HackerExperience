defmodule Test.Setup.Process do
  use Test.Setup.Definition
  alias Game.Process.Executable
  alias Game.{Process, ProcessRegistry}
  alias Test.Setup.Process.Spec, as: ProcessSpecSetup

  @doc """
  Opts:
  - type: Defines process type. A random type is picked if unset
  - spec: Custom opts for the `spec` implementation. Consult docs at `spec/2`. Opts include:
    - params: Process params. If unset, per-process defaults are applied
    - meta: Process meta. If unset, per-process defaults are applied (new data may be created)
  - objective: Modify the process objective
  - static: Modify the process static resources. Accepts: %{paused: R}, %{paused: R, running: R}
            or R. Any missing information will default to using the original process static.
  """
  def new(server_id, opts \\ []) do
    spec_opts = (opts[:spec] || []) ++ [type: opts[:type]]
    spec = spec(server_id, spec_opts)

    # Create the process using Executable
    %{entity_id: entity_id} = Svc.Server.fetch!(by_id: server_id)

    {:ok, process, _} =
      Executable.execute(spec.module, server_id, entity_id, spec.params, spec.meta)

    process = maybe_update_resources(process, opts)

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
  - type: Defines process type. If not set, a random process is used
  - params: Overwrites the process params. If nil, a per-process default is applied
  - meta: Overwrites the process meta. If nil, a per-process default is applied
  - <custom>: Each process may define their own custom opts for improved ergonomics
  """
  def spec(server_id, opts \\ []) do
    if opts[:type] do
      ProcessSpecSetup.spec(opts[:type], server_id, opts)
    else
      ProcessSpecSetup.random(server_id, opts)
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

    new_resources =
      process.resources
      |> Map.put(:objective, opts[:objective] || process.resources.objective)
      |> Map.put(:allocated, opts[:allocated] || process.resources.allocated)
      |> Map.put(:static, gen_static_value.())
      |> Map.put(:l_dynamic, opts[:l_dynamic] || process.resources.l_dynamic)

    Core.with_context(:server, process.server_id, :write, fn ->
      process
      |> Process.update(%{resources: new_resources})
      |> DB.update!()

      Svc.Process.fetch!(by_id: process.id)
    end)
  end
end
