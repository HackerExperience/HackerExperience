defmodule Game.Services.TOP do
  alias Game.Process.Executable

  # TODO: Change to `defdelegate` if this ends up being the final implementation
  def execute(process_mod, server_id, entity_id, params, meta) do
    Executable.execute(process_mod, server_id, entity_id, params, meta)
  end
end
