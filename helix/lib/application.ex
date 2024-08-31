defmodule Helix.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children =
      [
        {Task,
         fn ->
           # Loading Helix modules will block the Webserver from starting
           eagerly_load_helix_modules()
           # But loading dependencies modules is asynchronous and won't block serving requests
           eagerly_load_dependencies_modules()
         end},
        {PartitionSupervisor, child_spec: Task.Supervisor, name: Helix.TaskSupervisor},
        {Core.Supervisor, name: Core.Supervisor},
        {Webserver.Supervisor, name: Webserver.Supervisor}
      ]

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Some modules are dynamically called, and if they are not previously loaded the return of
  `Kernel.function_exported?/3` may be misleading. Examples include Webserver hooks and Event
  triggers.

  Instead of having to remember to load these modules on demand, I've made the decision to simply
  load all of them upfront. This improves the readability of the relevant portions of the code and
  avoids errors where the developer forgot to load a module.

  In order to avoid hard-to-debug issues, I'm also explicitly blocking the webserver from starting
  up until all modules are loaded.
  """
  def wait_until_helix_modules_are_loaded(attempts \\ 0) do
    cond do
      :persistent_term.get(:helix_loaded_all_modules, false) ->
        :ok

      attempts == 100 ->
        raise "Did not load all modules after 1 second"

      true ->
        :timer.sleep(10)
        wait_until_helix_modules_are_loaded(attempts + 1)
    end
  end

  @doc """
  Loads every Helix Elixir module. See additinal context at `wait_until_helix_modules_are_loaded/1`.
  """
  def eagerly_load_helix_modules do
    {time, _} =
      :timer.tc(fn ->
        :helix
        |> :application.get_key(:modules)
        |> elem(1)
        |> Enum.each(&Code.ensure_loaded/1)
      end)

    Logger.info("Loaded helix modules in #{Float.round(time / 1000, 1)}ms")
    :persistent_term.put(:helix_loaded_all_modules, true)
  end

  # The goal of this is to eliminate the long tail latency of the lucky first few requests that
  # trigger the dynamic loading of (dependencies) modules.
  defp eagerly_load_dependencies_modules do
    {time, _} =
      :timer.tc(fn ->
        :application.which_applications()
        |> Enum.map(fn {app, _, _} -> app end)
        |> Enum.map(fn dep -> :application.get_key(dep, :modules) |> elem(1) end)
        |> List.flatten()
        |> Enum.each(&Code.ensure_loaded/1)
      end)

    Logger.info("Loaded dependencies modules in #{trunc(time / 1000)}ms")
  end
end
