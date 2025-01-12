defmodule Game.Process.Supervisor do
  use Supervisor

  alias Game.Process.TOP

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
           # Let's wait for FeebDB to be fully booted (so the queries are available)
           Feeb.DB.Boot.wait_boot!()

           TOP.on_boot({:multiplayer, 1})
           TOP.on_boot({:singleplayer, 1})
         end}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
