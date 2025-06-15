defmodule Game.Process.Viewable.Behaviour do
  alias Game.{Process, Entity}

  @callback spec() :: norm_struct :: struct()
  @callback render_data(Process.t(), process_data :: struct, Entity.id()) :: map
end
