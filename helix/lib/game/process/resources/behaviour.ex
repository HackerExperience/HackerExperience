defmodule Game.Process.Resources.Behaviour do
  @moduledoc """
  Behaviour that any implementation for a Resource element needs to comply with.
  """

  alias Game.Process
  alias Game.Process.Resources

  alias __MODULE__.Default.Implementation, as: DefaultImplementation

  @type name :: Resources.name()
  @type resource :: Resources.t()

  @type v ::
          DefaultImplementation.v()

  @callback initial(name) :: v
  @callback fmt_value(name, term) :: v

  @callback op_map(name, v, v, (v, v -> v)) :: v
  @callback map(name, v, (v -> v)) :: v
  @callback reduce(name, v, term, (v, term -> term)) :: term

  @callback allocate_static(name, Process.t()) :: v
  @callback allocate_dynamic(name, v, v, Process.t()) :: v
  @callback get_shares(name, Process.t()) :: v
  @callback resource_per_share(name, v, v) :: v

  @callback overflow?(name, v) :: boolean
  @callback completed?(name, v, v) :: boolean
  @callback equal?(name, v, v) :: boolean

  @callback sum(name, v, v) :: v
  @callback sub(name, v, v) :: v
  @callback mul(name, v, v) :: v
  @callback div(name, v, v) :: v
end
