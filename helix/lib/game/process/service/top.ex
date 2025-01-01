defmodule Game.Services.TOP do
  alias Game.Process.TOP

  def execute(process_mod, server_id, params, meta) do
    TOP.execute(process_mod, server_id, params, meta)
  end

  def pause(process) do
    TOP.pause(process)
  end
end
