defmodule Helix.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children =
      [
        {Task, fn -> eagerly_load_all_modules() end},
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
  def wait_until_all_modules_are_loaded(attempts \\ 0) do
    cond do
      :persistent_term.get(:helix_loaded_all_modules, false) ->
        :ok

      attempts == 100 ->
        raise "Did not load all modules after 1 second"

      true ->
        :timer.sleep(10)
        wait_until_all_modules_are_loaded(attempts + 1)
    end
  end

  # See doc at `wait_until_all_modules_are_loaded`
  defp eagerly_load_all_modules do
    {time, _} =
      :timer.tc(fn ->
        :helix
        |> :application.get_key(:modules)
        |> elem(1)
        |> Enum.each(&Code.ensure_loaded/1)
      end)

    Logger.info("Loaded all modules in #{Float.round(time / 1000, 1)}ms")
    :persistent_term.put(:helix_loaded_all_modules, true)
  end
end
