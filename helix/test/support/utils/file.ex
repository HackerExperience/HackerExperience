defmodule Test.Utils.File do
  use Test.Setup.Definition

  alias Game.{Entity, File, FileVisibility, Player, Server}

  def get_all_files(%Server.ID{} = server_id) do
    Core.with_context(:server, server_id, :read, fn ->
      DB.all(File)
    end)
  end

  def get_all_file_visibilities(%Player.ID{} = player_id),
    do: get_all_file_visibilities(Entity.ID.new(player_id))

  def get_all_file_visibilities(%Entity.ID{} = entity_id) do
    Core.with_context(:player, entity_id, :read, fn ->
      DB.all(FileVisibility)
    end)
  end
end
