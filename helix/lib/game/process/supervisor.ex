defmodule Game.Process.Supervisor do
  use Supervisor

  alias Game.Process.TOP

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    role = Helix.get_role()

    base_children =
      [
        {Registry, TOP.Registry.start_link_opts()},
        TOP.Supervisor
      ]

    children =
      case {role, Mix.env()} do
        {:lobby, _} -> []
        {_, :test} -> base_children
        {_, _} -> base_children ++ [top_boot(role)]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp top_boot(:singleplayer),
    do: top_boot_task(fn -> TOP.on_boot({:singleplayer, 1}) end)

  defp top_boot(:multiplayer),
    do: top_boot_task(fn -> TOP.on_boot({:multiplayer, 1}) end)

  defp top_boot(:all) do
    top_boot_task(fn ->
      TOP.on_boot({:singleplayer, 1})
      TOP.on_boot({:multiplayer, 1})
    end)
  end

  defp top_boot_task(boot_callback) do
    {Task,
     fn ->
       Feeb.DB.Boot.wait_boot!()
       boot_callback.()
     end}
  end
end
