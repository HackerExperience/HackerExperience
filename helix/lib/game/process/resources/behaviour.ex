defmodule Game.Process.Resources.Behaviour do
  # TODO: Document
  alias Game.Process.Resources

  @type name :: Resources.name()
  @type resource :: Resources.t()

  @type value ::
          Resources.Behaviour.Default.Implementation.t()

  @callback initial(name) :: value()

  # TODO: Add the other callbacks here
end
