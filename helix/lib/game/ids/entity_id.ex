defmodule Game.Entity.ID do
  @moduledoc """
  Because Player/Entity IDs are interchangeable, we don't use the generic macros for them.
  """

  @behaviour Feeb.DB.Type.Behaviour

  defstruct [:id]

  def new(id) when is_integer(id), do: %__MODULE__{id: id}
  def new(%__MODULE__{} = id), do: id

  @impl true
  def sqlite_type, do: :integer

  @impl true
  def cast!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}
  def cast!(%__MODULE__{} = id, _, _), do: id
  def cast!(%Game.Player.ID{id: player_id}, _, _), do: %__MODULE__{id: player_id}

  @impl true
  def dump!(v, _, _) when is_integer(v), do: v
  def dump!(%__MODULE__{id: v}, _, _), do: v

  @impl true
  def load!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}

  defimpl String.Chars do
    def to_string(%{id: id}), do: "#{id}"
  end
end
