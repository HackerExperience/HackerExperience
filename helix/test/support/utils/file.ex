defmodule Test.Utils.File do
  use Test.Setup.Definition

  alias Game.{File, Server}

  def get_all_files(%Server.ID{} = server_id) do
    Core.with_context(:server, server_id, :read, fn ->
      DB.all(File)
    end)
  end
end
