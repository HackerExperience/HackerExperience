defmodule Game.Process.Resources.Behaviour do
  alias Game.Process.Resources

  @type resource ::
          Resources.CPU.t()

  @callback initial() :: resource
end
