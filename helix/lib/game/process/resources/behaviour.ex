defmodule Game.Process.Resources.Behaviour do
  alias Game.Process.Resources

  @type name :: Resources.name()

  @type resource :: Resources.t()

  @callback initial(name) :: resource
end
