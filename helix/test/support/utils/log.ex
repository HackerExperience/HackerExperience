defmodule Test.Utils.Log do
  use Test.Setup.Definition

  alias Game.{Entity, Log, LogVisibility, Player, Server}

  def get_all_logs(%Server.ID{} = server_id) do
    Core.with_context(:server, server_id, :read, fn ->
      DB.all(Log)
    end)
  end

  def get_all_log_visibilities(%Player.ID{} = player_id),
    do: get_all_log_visibilities(Entity.ID.new(player_id))

  def get_all_log_visibilities(%Entity.ID{} = entity_id) do
    Core.with_context(:player, entity_id, :read, fn ->
      DB.all(LogVisibility)
    end)
  end

  def get_all_log_visibilities_on_server(%Player.ID{} = player_id, server_id) do
    get_all_log_visibilities_on_server(Entity.ID.new(player_id), server_id)
  end

  def get_all_log_visibilities_on_server(%Entity.ID{} = entity_id, %Server.ID{} = server_id) do
    get_all_log_visibilities(entity_id)
    |> Enum.filter(&(&1.server_id == server_id))
  end
end
