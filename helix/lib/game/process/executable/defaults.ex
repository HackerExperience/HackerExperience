defmodule Game.Process.Executable.Defaults do
  alias Game.{Tunnel}

  def custom(_, _, _, _),
    do: %{}

  def source_file(_, _, _, _, _), do: nil
  def target_file(_, _, _, _, _), do: nil
  def target_log(_, _, _, _, _), do: nil

  @doc """
  By default, if a Tunnel is defined in the `meta` input, then we will use it as the source tunnel.
  """
  def source_tunnel(_, _, _, %{tunnel: %Tunnel{id: tunnel_id}}, _), do: tunnel_id
  def source_tunnel(_, _, _, _, _), do: nil
end
