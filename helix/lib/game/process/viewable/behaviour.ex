defmodule Game.Process.Viewable.Behaviour do
  alias Core.{Process, Entity}

  @callback spec() :: Norm.Spec.t()
  @callback render_data(Process.t(), process_data :: struct, Entity.id()) :: map
end
