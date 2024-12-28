defmodule Game.Process.Supervisor do
  use Supervisor

  alias Game.Process.TOP

  @registry_opts [keys: :unique, name: @registry_name, partitions: System.schedulers_online()]

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      [
        {Registry, TOP.Registry.start_link_opts()},
        TOP.Supervisor,
        {Task,
         fn ->
           Helix.Application.wait_until_helix_modules_are_loaded()
           TOP.on_boot({:multiplayer, 1})
           TOP.on_boot({:singleplayer, 1})
         end}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
