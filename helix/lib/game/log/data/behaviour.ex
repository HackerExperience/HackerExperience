defmodule Game.Log.Data.Behaviour do
  @callback spec() :: norm_struct :: struct()
  @callback new(map) :: struct
  @callback dump!(struct) :: map
  @callback load!(map) :: struct
  @callback cast_input!(external_input :: map) :: struct
  @callback valid?(struct) :: boolean
  @callback render(struct) :: map
end
